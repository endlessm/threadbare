# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready():
	_update_story_quest_progress_visibility()
	GameState.collected_items_changed.connect(
		func(_new_items): _update_story_quest_progress_visibility()
	)


func _update_story_quest_progress_visibility():
	hud.change_story_quest_progress_visibility(eternal_loom.is_item_offering_possible())
