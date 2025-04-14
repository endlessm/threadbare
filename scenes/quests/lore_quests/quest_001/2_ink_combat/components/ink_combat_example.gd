# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var ink_combat_logic: InkCombatLogic = %InkCombatLogic
@onready var collectible_item: CollectibleItem = %CollectibleItem


func _ready() -> void:
	ink_combat_logic.goal_reached.connect(_on_goal_reached)
	ink_combat_logic.start()


func _on_goal_reached() -> void:
	collectible_item.reveal()
