# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var player: Player = %Player
@onready var void_chasing: CharacterBody2D = %VoidChasing


func _on_button_item_collected() -> void:
	GameState.set_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1, true)

	# Zoom out the camera when collecting the powerup, because now the player
	# can throw a longer thread:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(0.5, 0.5), 1.0)
	void_chasing.start(player)
