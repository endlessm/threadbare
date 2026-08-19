# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	var hook := body.get_node("%PlayerHook") as PlayerHook
	if hook:
		hook.hook_string_texture = preload(
			"res://scenes/game_elements/characters/player/components/hook-string-2.png"
		)
