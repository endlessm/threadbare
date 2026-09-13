# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
@abstract class_name BaseCanvasItemBehavior
extends Node
## @experimental
##
## Base class for canvas item behaviors.

## The controlled canvas item.[br][br]
##
## [b]Note:[/b] If the parent node is a CanvasItem and canvas_item isn't set,
## the parent node will be automatically assigned to this variable.
@export var canvas_item: CanvasItem:
	set = _set_canvas_item


func _enter_tree() -> void:
	if not canvas_item and get_parent() is CanvasItem:
		canvas_item = get_parent()


func _set_canvas_item(new_canvas_item: CanvasItem) -> void:
	canvas_item = new_canvas_item
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not canvas_item:
		warnings.append("Canvas item must be set.")
	return warnings
