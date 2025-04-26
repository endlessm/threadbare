# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

signal goal_reached

@export var intro_dialogue: DialogueResource

@onready var fill_game_logic: FillGameLogic = %FillGameLogic


func _ready() -> void:
	if intro_dialogue:
		DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self])
		await DialogueManager.dialogue_ended

	fill_game_logic.goal_reached.connect(_on_goal_reached)
	fill_game_logic.start()


func _on_goal_reached() -> void:
	goal_reached.emit()
