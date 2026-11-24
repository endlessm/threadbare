# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorScript
## Shows how the level scenes of a quest are linked to each other
##
## Edit [const QUEST_DIRECTORY] then run this in the editor. The report goes to
## the Output panel, one for each quest in the directory, as found by
## [method Quest.enumerate]. Starting from the
## [member Quest.first_scene], it follows the [code]next_scene[/code] property
## of every node, like [SceneLink], [Cinematic] and [CollectibleItem], and
## lists:
## [br][br]
## - The links of each scene that is reached.[br]
## - Ends: scenes that return the player to the Home Scene, with
##   [member SceneLink.target] set to [constant SceneLink.Target.HOME_SCENE].
##   This is how a quest is expected to end.[br]
## - Broken links: values that don't point to an existing scene.[br]
## - Dead ends: reached scenes that link neither to another scene of the quest
##   nor to the Home Scene. This includes links hardcoded to a scene outside the
##   quest, like Fray's End, which should use the Home Scene target instead.[br]
## - Unreachable scenes: scenes of the quest folder that are never reached and
##   that nothing else uses, so they are not components. A scene is used if a
##   scene or resource of the project depends on it, or if a script mentions
##   its path or UID, as in [code]preload()[/code].[br]
## - Scripts of the quest that change scene in code, which this can't follow.
## [br][br]
## At the end it prints the graph as a Mermaid flowchart, which can be pasted
## in a GitHub comment between [code]```mermaid[/code] and [code]```[/code].
## [br][br]
## Links are read from the scene files, so a [code]next_scene[/code] that is
## only set in code is not found. Links inside instanced scenes are not
## followed either, only the ones set on the instance itself.

## Where to look for quests: each of its subdirectories with a quest.tres.
const QUEST_DIRECTORY := "res://scenes/quests/story_quests"

const LINK_PROPERTY := &"next_scene"
const TARGET_PROPERTY := &"target"
## Value of [constant SceneLink.Target.HOME_SCENE]. Not referenced directly, so
## this script doesn't need SceneLink and its autoloads to compile, and can also
## run headless.
const HOME_SCENE_TARGET := 1

## Target of the links that return to the Home Scene.
const HOME := "home"


func _run() -> void:
	var quests := Quest.enumerate(QUEST_DIRECTORY)
	if quests.is_empty():
		push_error("No quests found in %s" % QUEST_DIRECTORY)
		return
	for quest in quests:
		print("\n".join(report(quest)))
		print()


## Returns the report lines for [param quest].
static func report(quest: Quest) -> PackedStringArray:
	var lines := PackedStringArray()
	var quest_folder := quest.resource_path.get_base_dir() + "/"
	lines.append("Scene graph of %s" % quest.resource_path)
	lines.append("(Paths in the quest are relative to %s)" % quest_folder)
	lines.append("")

	var start := _resolve(quest.first_scene)
	if start.is_empty():
		lines.append("first_scene is broken: '%s'" % quest.first_scene)
		return lines
	lines.append("Start: %s" % _short(start, quest_folder))
	lines.append("")

	# Walk the graph from the first scene.
	var reached: Array[String] = []
	var links: Array[Dictionary] = []
	var pending: Array[String] = [start]
	while not pending.is_empty():
		var scene_path: String = pending.pop_front()
		if scene_path in reached:
			continue
		reached.append(scene_path)
		for link in _find_links(scene_path):
			links.append(link)
			var target: String = link.target
			var inside := target.begins_with(quest_folder)
			if inside and target not in reached and target not in pending:
				pending.append(target)

	var ends := PackedStringArray()
	var broken := PackedStringArray()
	var dead_ends := PackedStringArray()
	for scene_path in reached:
		lines.append(_short(scene_path, quest_folder))
		var scene_links := links.filter(
			func(link: Dictionary) -> bool:
				return link.from == scene_path,
		)
		if scene_links.is_empty():
			lines.append("  (no links)")
		var continues := false
		var outside := PackedStringArray()
		for link: Dictionary in scene_links:
			var node_label: String = link.node + (" (script default)" if link.default else "")
			var target: String = link.target
			if target == HOME:
				lines.append("  %s -> Home Scene" % node_label)
				continues = true
			elif target.is_empty():
				lines.append("  %s -> BROKEN '%s'" % [node_label, link.value])
				broken.append(
					"%s %s: '%s'" % [_short(scene_path, quest_folder), link.node, link.value]
				)
			elif not target.begins_with(quest_folder):
				lines.append("  %s -> %s (outside the quest)" % [node_label, target])
				outside.append(target)
			else:
				lines.append("  %s -> %s" % [node_label, _short(target, quest_folder)])
				continues = true
		if scene_links.any(
			func(link: Dictionary) -> bool:
				return link.target == HOME,
		):
			ends.append(_short(scene_path, quest_folder))
		if not continues:
			var note := ""
			if not outside.is_empty():
				note = " (links to %s instead of the Home Scene)" % ", ".join(outside)
			dead_ends.append(_short(scene_path, quest_folder) + note)
	lines.append("")

	if ends.is_empty():
		lines.append("Ends: none, the quest never returns to the Home Scene")
		lines.append("")
	else:
		lines.append_array(_section("Ends", ends))
	lines.append_array(_section("Broken links", broken))
	lines.append_array(_section("Dead ends", dead_ends))
	var unreachable := PackedStringArray()
	var unreachable_paths := _find_unreachable(quest_folder, reached)
	# Scenes reached through code can still link to the unreachable ones.
	var quest_links: Array[Dictionary] = []
	if not unreachable_paths.is_empty():
		for scene_path in _find_files(quest_folder, "tscn"):
			quest_links.append_array(_find_links(scene_path))
	for scene_path in unreachable_paths:
		var sources := PackedStringArray()
		for link in quest_links:
			if link.target == scene_path:
				sources.append(_short(link.from, quest_folder))
		var note := "" if sources.is_empty() else " (linked from %s)" % ", ".join(sources)
		unreachable.append(_short(scene_path, quest_folder) + note)
	lines.append_array(_section("Unreachable scenes", unreachable))
	var scripts := PackedStringArray()
	for script_path in _find_scene_changing_scripts(quest_folder):
		scripts.append(_short(script_path, quest_folder))
	lines.append_array(_section("Scripts that change scene in code, check by hand", scripts))

	lines.append("Mermaid:")
	lines.append_array(_mermaid(start, reached, links))
	return lines


## Returns the links of the scene at [param scene_path], as dictionaries with
## the keys from, node, value, target (empty if broken, [const HOME] for the
## Home Scene) and default (true if the value is the default of the node's
## script).
static func _find_links(scene_path: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var scene := ResourceLoader.load(scene_path) as PackedScene
	if not scene:
		return found
	var state := scene.get_state()
	for index in state.get_node_count():
		var node_path := str(state.get_node_path(index)).trim_prefix("./")
		var node_name := str(state.get_node_name(0)) if node_path == "." else node_path
		var node_script := _get_saved_property(state, index, &"script") as Script

		if _is_scene_link(node_script):
			var link_target: Variant = _get_saved_property(state, index, TARGET_PROPERTY)
			if link_target == HOME_SCENE_TARGET:
				found.append(
					{
						"from": scene_path,
						"node": node_name,
						"value": "Home Scene",
						"target": HOME,
						"default": false,
					}
				)
				continue

		var value: Variant = _get_saved_property(state, index, LINK_PROPERTY)
		var is_default := false
		if value == null and node_script:
			value = node_script.get_property_default_value(LINK_PROPERTY)
			is_default = true
		if not value is String or (value as String).is_empty():
			continue
		found.append(
			{
				"from": scene_path,
				"node": node_name,
				"value": value,
				"target": _resolve(value),
				"default": is_default,
			}
		)
	return found


## Returns true if [param node_script] is [SceneLink] or extends it, like
## [Cinematic] and [CollectibleItem] do.
## [br][br]
## The scenes are not instantiated: the saved values are read from their
## [SceneState], so there is no node to test with [code]is SceneLink[/code].
## The class is matched by name, so this script doesn't depend on SceneLink
## and its autoloads, see [constant HOME_SCENE_TARGET].
static func _is_scene_link(node_script: Script) -> bool:
	while node_script:
		if node_script.get_global_name() == &"SceneLink":
			return true
		node_script = node_script.get_base_script()
	return false


## Returns the value of [param property] saved for the node at [param index],
## looking into the scene it instances if it isn't set on the node, or null.
static func _get_saved_property(state: SceneState, index: int, property: StringName) -> Variant:
	for property_index in state.get_node_property_count(index):
		if state.get_node_property_name(index, property_index) == property:
			return state.get_node_property_value(index, property_index)
	var instance := state.get_node_instance(index)
	if instance:
		return _get_saved_property(instance.get_state(), 0, property)
	return null


## Returns the path of [param path_or_uid] if it points to an existing file,
## or an empty string.
static func _resolve(path_or_uid: String) -> String:
	var path := path_or_uid
	if path_or_uid.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path_or_uid)
		if not ResourceUID.has_id(id):
			return ""
		path = ResourceUID.get_id_path(id)
	return path if ResourceLoader.exists(path) else ""


## Returns the scenes of [param quest_folder] that weren't reached and that
## nothing else uses.
static func _find_unreachable(quest_folder: String, reached: Array[String]) -> Array[String]:
	var candidates := _find_files(quest_folder, "tscn").filter(
		func(scene_path: String) -> bool:
			return scene_path not in reached,
	)
	if candidates.is_empty():
		return candidates

	# Links in next_scene are plain strings, so they aren't dependencies.
	var used: Dictionary[String, bool] = { }
	for resource_path in _find_files("res://scenes", "tscn") + _find_files("res://scenes", "tres"):
		for dependency in ResourceLoader.get_dependencies(resource_path):
			used[dependency.get_slice("::", 2) if dependency.contains("::") else dependency] = true

	var script_texts := PackedStringArray()
	for script_path in _find_files("res://scenes", "gd"):
		script_texts.append(FileAccess.get_file_as_string(script_path))
	var all_scripts := "\n".join(script_texts)

	return candidates.filter(
		func(scene_path: String) -> bool:
			if scene_path in used:
				return false
			var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(scene_path))
			return not (all_scripts.contains(scene_path.get_file()) or all_scripts.contains(uid)),
	)


static func _find_scene_changing_scripts(quest_folder: String) -> Array[String]:
	return _find_files(quest_folder, "gd").filter(
		func(script_path: String) -> bool:
			return FileAccess.get_file_as_string(script_path).contains("SceneSwitcher."),
	)


static func _find_files(folder: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	for file_name in ResourceLoader.list_directory(folder):
		var path := folder.path_join(file_name)
		if file_name.ends_with("/"):
			found.append_array(_find_files(path.trim_suffix("/"), extension))
		elif file_name.get_extension() == extension:
			found.append(path)
	return found


static func _section(title: String, items: PackedStringArray) -> PackedStringArray:
	var lines := PackedStringArray([title + (": none" if items.is_empty() else ":")])
	for item in items:
		lines.append("  " + item)
	lines.append("")
	return lines


static func _short(path: String, quest_folder: String) -> String:
	return path.trim_prefix(quest_folder)


static func _mermaid(
	start: String,
	reached: Array[String],
	links: Array[Dictionary],
) -> PackedStringArray:
	# Arrays and dictionaries, unlike packed arrays, are shared with the lambda.
	var node_lines: Array[String] = []
	var edge_lines: Array[String] = []
	var ids: Dictionary[String, String] = { }
	var get_id := func(key: String, label: String) -> String:
		if key not in ids:
			ids[key] = "s%d" % ids.size()
			node_lines.append('  %s["%s"]' % [ids[key], label.replace('"', "'")])
		return ids[key]
	get_id.call("start", "Start")
	for scene_path in reached:
		get_id.call(scene_path, scene_path.get_file().get_basename())
	edge_lines.append("  %s --> %s" % [ids["start"], ids[start]])
	for link in links:
		var target: String = link.target
		var target_id: String
		if target == HOME:
			target_id = get_id.call(HOME, "Home Scene")
		elif target.is_empty():
			target_id = get_id.call("broken " + link.value, "Broken: " + link.value)
		else:
			target_id = get_id.call(target, target.get_file().get_basename())
		var node_label: String = (link.node as String).get_file()
		edge_lines.append(
			'  %s -->|"%s"| %s' % [ids[link.from], node_label.replace('"', "'"), target_id]
		)
	var lines := PackedStringArray(["flowchart TD"])
	lines.append_array(node_lines)
	lines.append_array(edge_lines)
	return lines
