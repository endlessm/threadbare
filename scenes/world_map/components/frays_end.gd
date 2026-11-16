# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready() -> void:
	_update_story_quest_progress_visibility()
	GameState.collected_items_changed.connect(_update_story_quest_progress_visibility)


func _update_story_quest_progress_visibility(_new_items: Array[InventoryItem] = []) -> void:
	hud.change_story_quest_progress_visibility(eternal_loom.is_item_offering_possible())
