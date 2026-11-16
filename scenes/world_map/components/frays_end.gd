# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready() -> void:
	_update_story_quest_progress_visibility()
	GameState.global.item_collected.connect(_update_story_quest_progress_visibility)
	GameState.global.item_consumed.connect(_update_story_quest_progress_visibility)


func _update_story_quest_progress_visibility(_item: InventoryItem = null) -> void:
	hud.change_story_quest_progress_visibility(eternal_loom.is_item_offering_possible())
