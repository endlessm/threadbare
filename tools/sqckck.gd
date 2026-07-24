# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends MainLoop
## StoryQuest Construction Kit Construction Kit
##
## Prunes the game's source tree to make a reduced-size bundle that can be used
## as the basis for a StoryQuest.

const GitDescribeExport = preload("res://addons/threadbare_git_describe/export.gd")

# TODO: this should be Dev Island
const HOME_SCENE := "res://scenes/menus/title/title_screen.tscn"
const TEMPLATE_QUEST := "res://scenes/quests/template_quests/NO_EDIT/quest.tres"

const DELETE_PATHS := [
	"res://assets/third_party/tiny-swords-non-cc0",
	"res://scenes/quests/lore_quests",
	"res://scenes/quests/story_quests",
	"res://scenes/world_map",
]


func rm_rf(path: String) -> void:
	# You can only delete empty folders, so using DirAccess.remove() means
	# traversing the whole folder tree and deleting each leaf before its parent
	# folder. But you can trash a non-empty folder in a single step!
	var global_path := ProjectSettings.globalize_path(path)
	var ret := OS.move_to_trash(global_path)
	if ret != OK:
		push_error("Failed to trash ", global_path, ": ", error_string(ret))


func _process(_delta: float) -> bool:
	var home_scene := ResourceUID.path_to_uid(HOME_SCENE)
	ProjectSettings.set_setting(ThreadbareProjectSettings.HOME_SCENE, home_scene)

	var opening_quest := ResourceUID.path_to_uid(TEMPLATE_QUEST)
	ProjectSettings.set_setting(ThreadbareProjectSettings.OPENING_QUEST, opening_quest)

	ProjectSettings.set_setting("application/config/name", "Threadbare StoryQuest Kit")
	GitDescribeExport.set_versions()

	if ProjectSettings.save() != OK:
		push_error("Failed to save project settings")

	for path: String in DELETE_PATHS:
		rm_rf(path)

	return true  # End the main loop
