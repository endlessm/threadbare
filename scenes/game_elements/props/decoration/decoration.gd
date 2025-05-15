# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Decoration
extends Node2D

## Texture of the inner node %Sprite2D of type Sprite2D
@export var texture: Texture2D:
	set = _set_texture

## Flip horizontally the inner node %Sprite2D of type Sprite2D
@export var flip_h: bool:
	set = _set_flip_h

## Flip vertically the inner node %Sprite2D of type Sprite2D
@export var flip_v: bool:
	set = _set_flip_v

## Offset the inner node %Sprite2D of type Sprite2D
@export var offset: Vector2:
	set = _set_offset

@onready var sprite_2d: Sprite2D = %Sprite2D


func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_node_ready():
		return
	if texture != null:
		sprite_2d.texture = texture


func _set_flip_h(new_flip_h: bool) -> void:
	flip_h = new_flip_h
	if not is_node_ready():
		return
	sprite_2d.flip_h = flip_h


func _set_flip_v(new_flip_v: bool) -> void:
	flip_v = new_flip_v
	if not is_node_ready():
		return
	sprite_2d.flip_v = flip_v


func _set_offset(new_offset: Vector2) -> void:
	offset = new_offset
	if not is_node_ready():
		return
	sprite_2d.offset = offset


func _ready() -> void:
	_set_texture(texture)
	_set_flip_h(flip_h)
	_set_flip_v(flip_v)
	_set_offset(offset)
