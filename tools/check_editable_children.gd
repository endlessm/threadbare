# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CheckEditableChildren
extends EditorScript
## Reports how scenes use "Editable Children" on instances of other scenes
##
## Edit [const ROOT_FOLDER] then run this in the editor. The report goes to the
## Output panel. For each scene with editable children it lists:
## [br][br]
## - Instances with editable children that change nothing inside, so the option
##   can be turned off.[br]
## - Redundant changes: properties of a child node set to the value the child
##   would have anyway. This is often an accident: a [code]@tool[/code] script
##   copies an exported property of the instance root into a child, and with
##   editable children on, the editor saves the copy too. Clear these.[br]
## - How many properties are changed and nodes added inside the instances.
## [br][br]
## At the end, it tallies which child properties are changed, grouped by the
## instanced scene. A property changed on many instances is a sign the instanced
## scene should export it.
## [br][br]
## To find the value a child would have anyway, each instanced scene is
## instantiated with the same root properties as the instance, and briefly added
## to the editor's scene tree so its [code]@tool[/code] scripts run. Values that
## are random, or set by scripts that only run in game, can't be predicted.

const Util = preload("./util.gd")

## Where to look for scenes. Everything under it is checked.
const ROOT_FOLDER := "res://scenes/quests/story_quests"

## How many entries of the final tally to print.
const TALLY_SIZE := 30


func _run() -> void:
	var tally: Dictionary[String, int] = { }
	var scene_count := 0
	var editable_count := 0
	var unused_count := 0
	var redundant_count := 0

	for scene: PackedScene in Util.find_scenes(ROOT_FOLDER, _has_editable_children):
		var report := _check_scene(scene, tally)
		scene_count += 1
		editable_count += report.editable
		unused_count += report.unused.size()
		redundant_count += report.redundant.size()

		print(
			(
				"\n%s: %d editable instances, %d properties changed and %d nodes added inside"
				% [scene.resource_path, report.editable, report.changed, report.added]
			)
		)
		if not report.unused.is_empty():
			print("  Editable children that change nothing inside: %d" % report.unused.size())
			for path: String in report.unused:
				print("    ", path)
		if not report.redundant.is_empty():
			print("  Redundant changes: %d" % report.redundant.size())
			for change: String in report.redundant:
				print("    ", change)

	print(
		(
			(
				"\nScenes under %s with editable children: %d, editable instances: %d, "
				+ "changing nothing: %d, redundant changes: %d"
			)
			% [ROOT_FOLDER, scene_count, editable_count, unused_count, redundant_count]
		)
	)

	var keys := tally.keys()
	keys.sort_custom(
		func(a: String, b: String) -> bool:
			return tally[a] > tally[b],
	)
	print("\nMost changed child properties, by instanced scene:")
	for key: String in keys.slice(0, TALLY_SIZE):
		print("  %4d  %s" % [tally[key], key])


## Find the scenes cheaply by text, so that only those get loaded.
func _has_editable_children(scene_path: String) -> bool:
	return FileAccess.get_file_as_string(scene_path).contains("\n[editable path=")


## The paths of the instances with editable children in [param scene_path].
## [SceneState] doesn't expose them to scripts, so they are read from the
## [code].tscn[/code] file, where each is a single [code][editable][/code] line.
func _editable_paths(scene_path: String) -> Array[String]:
	var editable_line := RegEx.create_from_string('(?m)^\\[editable path="([^"]+)"\\]$')
	var paths: Array[String] = []
	for found: RegExMatch in editable_line.search_all(FileAccess.get_file_as_string(scene_path)):
		paths.append(found.get_string(1))
	return paths


## Check one scene. Returns a [Dictionary] with the counts and lists to report,
## and adds to [param tally] the child properties it changes.
func _check_scene(scene: PackedScene, tally: Dictionary[String, int]) -> Dictionary:
	var state := scene.get_state()
	var editable := _editable_paths(scene.resource_path)

	# Instances of other scenes, by node path. Instances nested inside these
	# aren't listed, because they belong to the instanced scene.
	var instances: Dictionary[String, int] = { }
	for idx in range(1, state.get_node_count()):
		if state.get_node_instance(idx):
			instances[_node_path(state, idx)] = idx

	var used: Dictionary[String, bool] = { }
	var redundant := PackedStringArray()
	var changed := 0
	var added := 0

	var holder := Node.new()
	EditorInterface.get_base_control().add_child(holder)
	var instantiated: Dictionary[String, Node] = { }

	for idx in range(1, state.get_node_count()):
		var path := _node_path(state, idx)
		var editable_roots := _ancestors_in(editable, path)
		if editable_roots.is_empty():
			continue
		for editable_root: String in editable_roots:
			used[editable_root] = true

		if state.get_node_type(idx) or state.get_node_instance(idx):
			added += 1
			continue

		# The node exists in an instanced scene, and this changes some of its
		# properties.
		var instance_path := _ancestors_in(instances.keys(), path)[-1]
		if not instantiated.has(instance_path):
			instantiated[instance_path] = _instantiate_like(state, instances[instance_path], holder)
		var relative := path.trim_prefix(instance_path + "/")
		var original := instantiated[instance_path].get_node_or_null(relative)
		var scene_file := state.get_node_instance(instances[instance_path]).resource_path.get_file()

		var properties := Util.node_properties(state, idx)
		for prop_name: StringName in properties:
			var value: Variant = properties[prop_name]
			changed += 1
			var key := "%s  %s.%s" % [scene_file, relative, prop_name]
			tally[key] = tally.get(key, 0) + 1
			if original and _is_same(original.get(prop_name), value):
				redundant.append("%s.%s" % [path, prop_name])

	holder.free()

	var unused := PackedStringArray()
	for editable_path: String in editable:
		if not used.has(editable_path):
			unused.append(editable_path)

	return {
		"editable": editable.size(),
		"unused": unused,
		"redundant": redundant,
		"changed": changed,
		"added": added,
	}


## Instantiate the scene of the instance at [param idx] with the same root
## properties, and add it to [param holder] so that its [code]@tool[/code]
## scripts run their [code]_ready()[/code].
func _instantiate_like(state: SceneState, idx: int, holder: Node) -> Node:
	var instance := state.get_node_instance(idx).instantiate()
	var properties := Util.node_properties(state, idx)
	for prop_name: StringName in properties:
		# Node references are stored as paths and resolved when the scene
		# loads, so they can't be set here.
		if not _has_node_path(properties[prop_name]):
			instance.set(prop_name, properties[prop_name])
	holder.add_child(instance)
	return instance


func _has_node_path(value: Variant) -> bool:
	if value is Array:
		return value.any(
			func(item: Variant) -> bool:
				return item is NodePath,
		)
	return value is NodePath


## The path of a node relative to the scene root, as written in the
## [code].tscn[/code] file, without the leading [code]./[/code].
func _node_path(state: SceneState, idx: int) -> String:
	return str(state.get_node_path(idx)).trim_prefix("./")


## The paths in [param candidates] that [param path] is under, shortest first.
func _ancestors_in(candidates: Array, path: String) -> Array[String]:
	var ancestors: Array[String] = []
	for candidate: String in candidates:
		if path.begins_with(candidate + "/"):
			ancestors.append(candidate)
	ancestors.sort_custom(
		func(a: String, b: String) -> bool:
			return a.length() < b.length(),
	)
	return ancestors


func _is_same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			return is_equal_approx(a, b)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR, TYPE_RECT2, TYPE_TRANSFORM2D:
			return a.is_equal_approx(b)
	return a == b
