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
## To see each change of a single scene with its value, use
## [code]show_editable_children_changes.gd[/code]. See
## [code]check_editable_children()[/code] in [code]util.gd[/code] for how the
## redundant changes are found.

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

	for scene: PackedScene in Util.find_scenes(ROOT_FOLDER, Util.has_editable_children):
		var report := Util.check_editable_children(scene, EditorInterface.get_base_control())
		var redundant := PackedStringArray()
		for change: Dictionary in report.changes:
			var key := "%s  %s.%s" % [change.instanced_scene, change.relative_path, change.property]
			tally[key] = tally.get(key, 0) + 1
			if change.redundant:
				redundant.append("%s.%s" % [change.path, change.property])

		scene_count += 1
		editable_count += report.editable.size()
		unused_count += report.unused.size()
		redundant_count += redundant.size()

		print(
			(
				"\n%s: %d editable instances, %d properties changed and %d nodes added inside"
				% [
					scene.resource_path,
					report.editable.size(),
					report.changes.size(),
					report.added_nodes.size(),
				]
			)
		)
		if not report.unused.is_empty():
			print("  Editable children that change nothing inside: %d" % report.unused.size())
			for path: String in report.unused:
				print("    ", path)
		if not redundant.is_empty():
			print("  Redundant changes: %d" % redundant.size())
			for change: String in redundant:
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
