# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends MainLoop
## StoryQuest Construction Kit Construction Kit
##
## Prunes the game's source tree to make a reduced-size bundle that can be used
## as the basis for a StoryQuest.

const GitDescribeExport = preload("res://addons/threadbare_git_describe/export.gd")

const HOME_SCENE := "res://scenes/dev/dev_archipelago.tscn"

const TEMPLATE_QUEST := "res://scenes/quests/template_quests/NO_EDIT/quest.tres"


func _process(_delta: float) -> bool:
	var home_scene := ResourceUID.path_to_uid(HOME_SCENE)
	ProjectSettings.set_setting(ThreadbareProjectSettings.HOME_SCENE, home_scene)

	var opening_quest := ResourceUID.path_to_uid(TEMPLATE_QUEST)
	ProjectSettings.set_setting(ThreadbareProjectSettings.OPENING_QUEST, opening_quest)

	ProjectSettings.set_setting("application/config/name", "Threadbare StoryQuest Kit")
	GitDescribeExport.set_versions()

	if ProjectSettings.save() != OK:
		push_error("Failed to save project settings")

	return true  # End the main loop
