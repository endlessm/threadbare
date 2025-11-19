# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _on_interact_area_interaction_started(_player: Player, from_right: bool) -> void:
	animated_sprite_2d.flip_h = not from_right


func _on_interact_area_interaction_ended() -> void:
	animated_sprite_2d.flip_h = false
