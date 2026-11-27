# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Object


## Return a list of all scenes in the project that match the filter.
## filter accepts one argument, the path to a scene, and returns a boolean,
## true if the scene matches the filter.
static func find_scenes(
	root_folder: String = "res://",
	filter: Callable = func(_scene_path: String) -> bool:
		return true,
) -> Array[PackedScene]:
	var packed_scenes: Array[PackedScene] = []
	var err: Error

	var dirs: Array[String] = [root_folder]
	while not dirs.is_empty():
		var current_dir: String = dirs.pop_back()
		var dir := DirAccess.open(current_dir)
		if not dir:
			err = DirAccess.get_open_error()
			push_error("Failed to open", dir, ":", error_string(err))
			continue

		err = dir.list_dir_begin()
		if err != OK:
			push_error("Failed to list directory", dir, ":", error_string(err))
			continue

		var file_name := dir.get_next()
		while file_name != "":
			var path := current_dir.path_join(file_name)
			if dir.current_is_dir():
				dirs.push_back(path)
			elif file_name.ends_with(".tscn"):
				# The filter accepts a path rather than a PackedScene because
				# load()ing a PackedScene is expensive. Benchmarking crudely on
				# one laptop: with a filter that rejects all scenes, the loop
				# takes 60ms if the load() is after the filter call, but 4000 ms
				# if load() is before. During that time the editor UI is frozen.
				if filter.call(path):
					var scene := load(path) as PackedScene
					if scene:
						packed_scenes.push_back(scene)
			file_name = dir.get_next()
		dir.list_dir_end()

	return packed_scenes


## Return every file under [param folder], recursively. The folders in
## [param skip_folders], and everything under them, are left out. So is Godot's
## own .godot cache, which holds a copy of everything.
static func all_files(
	folder: String,
	skip_folders: PackedStringArray = PackedStringArray(),
) -> PackedStringArray:
	var files := PackedStringArray()
	var pending := PackedStringArray([folder])

	while not pending.is_empty():
		var current := pending[-1]
		pending.remove_at(pending.size() - 1)

		if current in skip_folders:
			continue

		for directory: String in DirAccess.get_directories_at(current):
			if directory != ".godot":
				pending.append(current.path_join(directory))

		for file: String in DirAccess.get_files_at(current):
			files.append(current.path_join(file))

	return files


## Return the properties that the scene sets on the node at [param idx] of
## [param scene_state], by name. Properties left at their default value aren't
## included, because they aren't saved in the scene.
static func node_properties(scene_state: SceneState, idx: int) -> Dictionary[StringName, Variant]:
	var properties: Dictionary[StringName, Variant] = { }
	for prop_idx: int in scene_state.get_node_property_count(idx):
		properties[scene_state.get_node_property_name(idx, prop_idx)] = (
			scene_state.get_node_property_value(idx, prop_idx)
		)
	return properties


## Return true if the scene at [param scene_path] has instances with editable
## children. It reads the file as text, because loading the scene is expensive.
static func has_editable_children(scene_path: String) -> bool:
	return FileAccess.get_file_as_string(scene_path).contains("\n[editable path=")


## Return the paths of the instances with editable children in
## [param scene_path]. [SceneState] doesn't expose them to scripts, so they are
## read from the [code].tscn[/code] file, where each is a single
## [code][editable][/code] line.
static func editable_paths(scene_path: String) -> Array[String]:
	var editable_line := RegEx.create_from_string('(?m)^\\[editable path="([^"]+)"\\]$')
	var paths: Array[String] = []
	for found: RegExMatch in editable_line.search_all(FileAccess.get_file_as_string(scene_path)):
		paths.append(found.get_string(1))
	return paths


## Check how [param scene] uses editable children. Return a [Dictionary] with:
## [br][br]
## - [code]editable[/code]: the paths of the instances with editable children.[br]
## - [code]unused[/code]: those of them that change nothing inside.[br]
## - [code]changes[/code]: one [Dictionary] for each property changed inside the
##   instances, with the [code]path[/code] of the node, the [code]property[/code]
##   and its [code]value[/code]. Also [code]redundant[/code], true if the node
##   would have that value anyway, and the [code]instanced_scene[/code] file and
##   the [code]relative_path[/code] of the node in it.[br]
## - [code]added_nodes[/code]: the paths of the nodes added inside the instances.
## [br][br]
## To find the value a node would have anyway, each instanced scene is
## instantiated with the same root properties as the instance, and briefly added
## to [param parent] so its [code]@tool[/code] scripts run. Values that are
## random, or set by scripts that only run in game, can't be predicted.
static func check_editable_children(scene: PackedScene, parent: Node) -> Dictionary:
	var state := scene.get_state()
	var editable := editable_paths(scene.resource_path)

	# Instances of other scenes, by node path. Instances nested inside these
	# aren't listed, because they belong to the instanced scene.
	var instances: Dictionary[String, int] = { }
	for idx in range(1, state.get_node_count()):
		if state.get_node_instance(idx):
			instances[_node_path(state, idx)] = idx

	var used: Dictionary[String, bool] = { }
	var changes: Array[Dictionary] = []
	var added_nodes := PackedStringArray()

	var holder := Node.new()
	parent.add_child(holder)
	var instantiated: Dictionary[String, Node] = { }

	for idx in range(1, state.get_node_count()):
		var path := _node_path(state, idx)
		var editable_roots := _ancestors_in(editable, path)
		if editable_roots.is_empty():
			continue
		for editable_root: String in editable_roots:
			used[editable_root] = true

		if state.get_node_type(idx) or state.get_node_instance(idx):
			added_nodes.append(path)
			continue

		# The node exists in an instanced scene, and this changes some of its
		# properties.
		var instance_path := _ancestors_in(instances.keys(), path)[-1]
		if not instantiated.has(instance_path):
			instantiated[instance_path] = _instantiate_like(state, instances[instance_path], holder)
		var relative := path.trim_prefix(instance_path + "/")
		var original := instantiated[instance_path].get_node_or_null(relative)
		var scene_file := state.get_node_instance(instances[instance_path]).resource_path.get_file()

		var properties := node_properties(state, idx)
		for prop_name: StringName in properties:
			var value: Variant = properties[prop_name]
			changes.append(
				{
					"path": path,
					"property": prop_name,
					"value": value,
					"redundant": original != null and _is_same(original.get(prop_name), value),
					"instanced_scene": scene_file,
					"relative_path": relative,
				},
			)

	holder.free()

	var unused := PackedStringArray()
	for editable_path: String in editable:
		if not used.has(editable_path):
			unused.append(editable_path)

	return {
		"editable": editable,
		"unused": unused,
		"changes": changes,
		"added_nodes": added_nodes,
	}


## Instantiate the scene of the instance at [param idx] with the same root
## properties, and add it to [param holder] so that its [code]@tool[/code]
## scripts run their [code]_ready()[/code].
static func _instantiate_like(state: SceneState, idx: int, holder: Node) -> Node:
	var instance := state.get_node_instance(idx).instantiate()
	var properties := node_properties(state, idx)
	for prop_name: StringName in properties:
		# Node references are stored as paths and resolved when the scene
		# loads, so they can't be set here.
		if not _has_node_path(properties[prop_name]):
			instance.set(prop_name, properties[prop_name])
	holder.add_child(instance)
	return instance


static func _has_node_path(value: Variant) -> bool:
	if value is Array:
		return value.any(
			func(item: Variant) -> bool:
				return item is NodePath,
		)
	return value is NodePath


## The path of a node relative to the scene root, as written in the
## [code].tscn[/code] file, without the leading [code]./[/code].
static func _node_path(state: SceneState, idx: int) -> String:
	return str(state.get_node_path(idx)).trim_prefix("./")


## The paths in [param candidates] that [param path] is under, shortest first.
static func _ancestors_in(candidates: Array, path: String) -> Array[String]:
	var ancestors: Array[String] = []
	for candidate: String in candidates:
		if path.begins_with(candidate + "/"):
			ancestors.append(candidate)
	ancestors.sort_custom(
		func(a: String, b: String) -> bool:
			return a.length() < b.length(),
	)
	return ancestors


static func _is_same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			return is_equal_approx(a, b)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR, TYPE_RECT2, TYPE_TRANSFORM2D:
			return a.is_equal_approx(b)
	return a == b
