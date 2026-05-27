# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var interact_area: InteractArea
@export var talk_behavior: TalkBehavior
@export var path_walk_behavior: PathWalkBehavior
@export var cinematic: Cinematic
@export var sequence_puzzle: SequencePuzzle


func _ready() -> void:
	path_walk_behavior.ending_reached.connect(_on_ending_reached)
	if GameState.intro_dialogue_shown:
		walk_path()
	else:
		cinematic.cinematic_finished.connect(walk_path, CONNECT_ONE_SHOT)


func walk_path() -> void:
	# Don't let the player talk to him while walking.
	interact_area.disabled = true
	path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT


func _on_ending_reached() -> void:
	interact_area.disabled = false
	path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
	path_walk_behavior.character.velocity = Vector2.ZERO
