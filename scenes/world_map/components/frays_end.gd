# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name FraysEnd
extends Node2D

@onready var eternal_loom: EternalLoom = %EternalLoom
@onready var void_quest_unlocker: QuestProgressUnlocker = %VoidQuestUnlocker
@onready var dev_island_unlocker: QuestProgressUnlocker = %DevIslandUnlocker
@onready var exit_blocker: Area2D = %ExitBlocker


func _ready() -> void:
	_update_exit_blocker()
	if GameState.quest:
		GameState.quest.inventory.item_collected.connect(_update_exit_blocker)
		GameState.quest.inventory.item_consumed.connect(_update_exit_blocker)

	# Back to Fray's End after finishing playing all cutscenes.
	if GameState.global.facts.has("rewoven_cutscenes"):
		GameState.global.facts.erase("rewoven_cutscenes")
		eternal_loom.on_rewoven_finished()


func _update_exit_blocker(_item: InventoryItem = null) -> void:
	exit_blocker.set_deferred(&"monitoring", eternal_loom.is_item_offering_possible())
	HudManager.refresh_hud()
