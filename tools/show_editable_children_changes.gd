# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ShowEditableChildrenChanges
extends EditorScript
## Lists what the open scene changes inside instances with "Editable Children"
##
## Open a scene, save it, then run this in the editor. It reads the saved file.
## The report goes to the Output panel. It lists:
## [br][br]
## - Instances with editable children that change nothing inside, so the option
##   can be turned off.[br]
## - Each property changed inside the instances, with its value. Redundant ones
##   are marked: the node would have that value anyway, so clear them.[br]
## - Each node added inside the instances.
## [br][br]
## To check all the scenes in a folder, use [code]check_editable_children.gd[/code].

const Util = preload("./util.gd")

## Longer values are cut.
const MAX_VALUE_LENGTH := 100


func _run() -> void:
	var scene_root := get_scene()
	if not scene_root or scene_root.scene_file_path.is_empty():
		push_error("Open a saved scene first.")
		return

	var scene_path := scene_root.scene_file_path
	if not Util.has_editable_children(scene_path):
		print("\n%s has no editable children." % scene_path)
		return

	var scene := load(scene_path) as PackedScene
	var report := Util.check_editable_children(scene, EditorInterface.get_base_control())
	print(
		(
			"\n%s: %d editable instances, %d properties changed and %d nodes added inside"
			% [scene_path, report.editable.size(), report.changes.size(), report.added_nodes.size()]
		)
	)
	if not report.unused.is_empty():
		print("  Editable children that change nothing inside: %d" % report.unused.size())
		for path: String in report.unused:
			print("    ", path)
	if not report.changes.is_empty():
		print("  Changes (redundant ones are marked, clear them):")
		for change: Dictionary in report.changes:
			print(
				(
					"    %s.%s = %s%s"
					% [
						change.path,
						change.property,
						_format_value(change.value),
						"  (redundant)" if change.redundant else "",
					]
				)
			)
	if not report.added_nodes.is_empty():
		print("  Nodes added inside:")
		for path: String in report.added_nodes:
			print("    ", path)


## A short text for [param value]. Resources are shown by path, or by class if
## they are embedded in a scene.
func _format_value(value: Variant) -> String:
	if value is Resource:
		var resource: Resource = value
		if resource.resource_path.is_empty() or resource.resource_path.contains("::"):
			var resource_class := resource.get_class()
			var resource_script := resource.get_script() as Script
			if resource_script and resource_script.get_global_name():
				resource_class = resource_script.get_global_name()
			return "<embedded %s>" % resource_class
		return resource.resource_path
	var text := var_to_str(value).replace("\n", " ")
	if text.length() > MAX_VALUE_LENGTH:
		text = text.left(MAX_VALUE_LENGTH) + "..."
	return text
