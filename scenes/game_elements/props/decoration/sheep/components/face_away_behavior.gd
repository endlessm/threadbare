# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Behavior to face a character in the opposite direction when interacted.
##
##

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var character: CharacterBody2D = get_parent()


func _on_interact_area_interaction_started(_player: Player, from_right: bool) -> void:
	var parent_is_flipped := character.global_transform.x.x < 0.0
	animated_sprite_2d.flip_h = from_right != parent_is_flipped
