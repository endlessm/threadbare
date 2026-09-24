# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node


func apply(player: Player, pet_animation: AnimatedSprite2D) -> void:
	var player_is_on_right := player.global_position.x > pet_animation.global_position.x
	var parent_is_flipped := pet_animation.global_transform.x.x < 0.0
	pet_animation.flip_h = player_is_on_right != parent_is_flipped
