# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var _player: CharacterBody2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
	var hook: PlayerHook = _player.get_node("%PlayerHook")
	if hook:
		hook.hook_string_texture = preload(
			"res://scenes/game_elements/characters/player/components/hook-string-2.png"
		)
