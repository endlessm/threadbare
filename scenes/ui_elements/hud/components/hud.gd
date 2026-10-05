# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var zone_name_display: PanelContainer = %ZoneNameDisplay
@onready var zone_unlocked_display: CanvasLayer = $ZoneUnlockedDisplay


func _ready() -> void:
	GameState.global.zone_changed.connect(_on_zone_changed)


func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility


func _on_zone_changed(zone_name: String, first_visit: bool) -> void:
	if GameState.scene.zone_name_displayed == zone_name:
		return
	GameState.scene.zone_name_displayed = zone_name
	if first_visit:
		zone_unlocked_display.animate(zone_name)
	else:
		zone_name_display.animate(zone_name)
