# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Character
extends CharacterBody2D

@export var character_name: String = ""

@export var look_at_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED:
	set = _set_look_at_side

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_look_at_side(new_look_at_side: Enums.LookAtSide) -> void:
	look_at_side = new_look_at_side
	if not is_node_ready():
		return
	animated_sprite_2d.flip_h = look_at_side == Enums.LookAtSide.LEFT

# TODO: Add a "being interrupted" or "is standing" boolean to stop walk behaviors?
