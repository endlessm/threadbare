# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ToggableLight
extends Node2D

signal light_enabled(num: int)
signal light_disabled(num: int)

@onready var light: PointLight2D = $PointLight2D

@export var light_color: Color = Color.WHITE:
	set = _set_light_color
@export var light_on: bool = false:
	set = _set_light_visibility

var order: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_light_color(light_color)
	_set_light_visibility(light_on)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_light_color(new_value: Color) -> void:
	light_color = new_value
	if light:
		light.color = new_value


func _set_light_visibility(is_on: bool) -> void:
	light_on = is_on
	if light:
		light.enabled = is_on

func _on_hookable_lever_toggled(is_on: bool) -> void:
	if is_on:
		light.enabled = true
		light_enabled.emit(order)
	else:
		light.enabled = false
		light_disabled.emit(order)
