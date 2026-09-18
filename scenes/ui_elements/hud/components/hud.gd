# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Hud extends CanvasLayer

@onready var story_quest_progress: StoryQuestProgress = %StoryQuestProgress


func _ready() -> void:
	hide_story_quest_progress()


func refresh_story_quest_progress() -> void:
	story_quest_progress.refresh()


func show_story_quest_progress() -> void:
	refresh_story_quest_progress()
	story_quest_progress.visible = true


func hide_story_quest_progress() -> void:
	story_quest_progress.visible = false
