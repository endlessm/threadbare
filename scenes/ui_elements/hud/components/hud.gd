# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var re_entry: PanelContainer = %ReEntry


func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility


func show_re_entry_zone(zone_name: String, time:int) -> void:
	await re_entry.animate_re_entry(zone_name, time)
