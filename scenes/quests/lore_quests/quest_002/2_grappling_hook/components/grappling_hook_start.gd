# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var _play_cinematic: bool = true

@onready var cinematic: Cinematic = $Cinematic
@onready var void_patrolling: CharacterBody2D = %VoidPatrolling
@onready var void_cover: TileMapCover = %Void


func _ready() -> void:
	if _play_cinematic:
		# Connect before starting, because the cinematic finishes right away if
		# its dialogue was already shown, for example after a defeat.
		cinematic.cinematic_finished.connect(void_cover.save, CONNECT_ONE_SHOT)
		cinematic.start()


func _on_spawn_point_from_powerup_player_teleported() -> void:
	# The player is coming back from the east, so the cinematic already played
	# the "eat_floor" animation and the Void enemy added tiles already.
	_play_cinematic = false
	if not is_node_ready():
		await ready
	void_patrolling.queue_free()
