# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: PanelContainer = %StoryQuestProgress


func change_story_quest_progress_visibility(visibility: bool) -> void:
	story_quest_progress.visible = visibility
