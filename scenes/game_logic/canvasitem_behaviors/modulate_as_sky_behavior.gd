# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ModulateAsSkyBehavior
extends Node
## @experimental
##
## Tint the canvas item according to the sky color.

## The controlled canvas item.
@export var canvas_item: CanvasItem:
	set = _set_canvas_item

var time_and_weather: TimeAndWeather


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


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	time_and_weather = get_tree().current_scene.get_node_or_null("TimeAndWeather")
	if not time_and_weather:
		process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not canvas_item:
		return
	canvas_item.modulate = time_and_weather.get_sky_color()
