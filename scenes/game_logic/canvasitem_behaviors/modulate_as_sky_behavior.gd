# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ModulateAsSkyBehavior
extends BaseCanvasItemBehavior
## @experimental
##
## Tint the canvas item according to the sky color.

var time_and_weather: TimeAndWeather


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	time_and_weather = get_tree().current_scene.get_node_or_null("TimeAndWeather")
	if not time_and_weather:
		process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	if not canvas_item:
		return
	canvas_item.modulate = time_and_weather.get_sky_color()
