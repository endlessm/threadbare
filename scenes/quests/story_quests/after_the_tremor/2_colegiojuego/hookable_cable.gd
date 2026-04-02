# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends StaticBody2D

## Texture of the inner node %Sprite2D of type Sprite2D
@export var texture: Texture2D:
	set = _set_texture

var is_on: bool = false

@onready var sprite_2d: Sprite2D = %Sprite2D

func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_node_ready():
		return
	if texture != null:
		sprite_2d.texture = texture


func _ready() -> void:
	_set_texture(texture)


func turn_on() -> void:
	is_on = true
	sprite_2d.modulate = Color(3, 3, 3)


func turn_off() -> void:
	if not is_on:
		return
	is_on = false
	sprite_2d.modulate = Color(0.6, 0.6, 0.6) # apagado (fallback)
