# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var fill_game_logic: FillGameLogic = %FillGameLogic
@onready var collectible_item: CollectibleItem = %CollectibleItem


func _ready() -> void:
	fill_game_logic.goal_reached.connect(_on_goal_reached)
	fill_game_logic.start()


func _on_goal_reached() -> void:
	collectible_item.reveal()
