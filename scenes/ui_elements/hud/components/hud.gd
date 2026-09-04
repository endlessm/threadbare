# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress
@onready var re_entry: PanelContainer = %re_entry # O $HBoxContainer/re_entry


func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility


func show_re_entry_zone(zone_name: String, time:int) -> void:
	if re_entry and re_entry.has_method("animate_re_entry"):
		await re_entry.animate_re_entry(zone_name, time)
