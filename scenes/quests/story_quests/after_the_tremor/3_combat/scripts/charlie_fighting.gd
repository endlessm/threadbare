# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends "res://scenes/game_elements/characters/player/components/player_fighting.gd"

@export var input_action: String = "repel"

func _ready() -> void:
	hit_box.body_entered.connect(_on_body_entered)
	air_stream.body_entered.connect(_on_air_stream_body_entered)

func _unhandled_input(_event: InputEvent) -> void:

	if Input.is_action_just_pressed(input_action):
		is_fighting = true
	elif Input.is_action_just_released(input_action):
		is_fighting = false

	
