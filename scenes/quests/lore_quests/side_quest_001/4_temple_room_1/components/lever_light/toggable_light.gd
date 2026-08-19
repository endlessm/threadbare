# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ToggableLight
extends Node2D

signal light_enabled(num: int)
signal light_disabled(num: int)

@export var light_color: Color = Color.WHITE:
	set = _set_light_color
@export var light_on: bool = false:
	set = _set_light_visibility

var order: int

@onready var light: PointLight2D = $PointLight2D


## Sets the light's color and whether the light should be on or off.
func _ready() -> void:
	_set_light_color(light_color)
	_set_light_visibility(light_on)


## Sets the selected color as the light's color.
func _set_light_color(new_value: Color) -> void:
	light_color = new_value
	if light:
		light.color = new_value


## Sets whether the light should start on or off, as specified in the editor.
func _set_light_visibility(is_on: bool) -> void:
	light_on = is_on
	if light:
		light.enabled = is_on


## When the lever is toggled on, it turns on the light. If it's off, the light turns off.
func _on_hookable_lever_toggled(is_on: bool) -> void:
	if is_on:
		light.enabled = true
		light_enabled.emit(order)
	else:
		light.enabled = false
		light_disabled.emit(order)
