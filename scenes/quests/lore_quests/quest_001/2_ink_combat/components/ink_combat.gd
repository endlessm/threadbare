# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var intro_dialogue: DialogueResource

@onready var fill_game_logic: FillGameLogic = %FillGameLogic
@onready var collectible_item: CollectibleItem = %CollectibleItem


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(intro_dialogue, "", [self])
	await DialogueManager.dialogue_ended
	# Add a short delay so the player doesn"t attack when closing the dialogue:
	await get_tree().create_timer(0.5).timeout
	fill_game_logic.goal_reached.connect(_on_goal_reached)
	fill_game_logic.start()


func _on_goal_reached() -> void:
	collectible_item.reveal()
