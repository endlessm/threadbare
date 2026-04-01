# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var _play_cinematic: bool = true

@onready var cinematic: Cinematic = $Cinematic
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var void_patrolling: CharacterBody2D = %VoidPatrolling


func _ready() -> void:
	if _play_cinematic:
		cinematic.start()


func _on_spawn_point_from_powerup_player_teleported() -> void:
	# The player is coming back from the east, so play the
	# animation directly. This is actually letting the Void
	# add tiles.
	_play_cinematic = false
	if not is_node_ready():
		await ready
	void_patrolling.visible = false
	animation_player.play(&"eat_floor")


func _on_grapple_powerup_collected() -> void:
	animation_player.play(&"show_input_hints")
