# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var eternal_loom: EternalLoom = %EternalLoom
@onready var void_quest_unlocker: QuestProgressUnlocker = %VoidQuestUnlocker
@onready var mythical_meadows_unlocker: QuestProgressUnlocker = %MythicalMeadowsUnlocker
@onready var exit_blocker: Area2D = %ExitBlocker


func _ready() -> void:
	_update_story_quest_progress_visibility()
	if GameState.quest:
		GameState.quest.inventory.item_collected.connect(_update_story_quest_progress_visibility)
		GameState.quest.inventory.item_consumed.connect(_update_story_quest_progress_visibility)


func _update_story_quest_progress_visibility(_item: InventoryItem = null) -> void:
	var end_of_quest := eternal_loom.is_item_offering_possible()
	hud.change_story_quest_progress_visibility(end_of_quest)
	exit_blocker.set_deferred(&"monitoring", end_of_quest)
