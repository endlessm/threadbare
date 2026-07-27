# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

@export var dialogue: DialogueResource
@export var title: String
@export var spawn_point: SpawnPoint


func _ready() -> void:
	body_entered.connect(_body_entered_cb)


func _body_entered_cb(body: Node2D) -> void:
	if not body is Player:
		return

	var player: Player = body
	player.input_walk_behavior.is_running = false
	player.input_walk_behavior.input_vector = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.take_control(self)

	DialogueManager.show_dialogue_balloon(dialogue, title, [player])
	await DialogueManager.dialogue_ended

	await (
		Transitions
		. do_transition(
			spawn_point.move_player_to_self_position,
		)
	)

	player.return_control(self)
