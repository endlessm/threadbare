# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
## Offers a choice of quests by scanning a given [member quest_directory].

## Emitted when the player chooses to play the given quest
signal play(quest: Quest)

## Template quest, which is expected to be blank and so is treated specially.
const STORY_QUEST_TEMPLATE := preload("res://scenes/quests/story_quests/template/quest.tres")

const QUEST_RESOURCE_NAME := "quest.tres"

## Directory to scan for quests. This directory should have 1 or more subdirectories, each of which
## have a [code]quest.tres[/code] file within.
@export_dir var quest_directory: String = "res://scenes/quests/story_quests"

var _selected_quest: Quest

@onready var quest_list: VBoxContainer = %QuestList
@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var authors: Label = %Authors
@onready var play_button: Button = %PlayButton


func _enumerate_quests() -> Array[Quest]:
	var has_template: bool = false
	var quests: Array[Quest]

	for dir in ResourceLoader.list_directory(quest_directory):
		var quest_path := quest_directory.path_join(dir).path_join(QUEST_RESOURCE_NAME)
		if ResourceLoader.exists(quest_path, "Quest"):
			var quest: Quest = ResourceLoader.load(quest_path, "Quest")
			if quest == STORY_QUEST_TEMPLATE:
				has_template = true
			else:
				quests.append(quest)

	if has_template:
		quests.append(STORY_QUEST_TEMPLATE)

	return quests


func _ready() -> void:
	var previous_button: Button = null
	for quest in _enumerate_quests():
		var button := Button.new()
		button.text = quest.get_title()
		button.theme_type_variation = "FlatButton"
		quest_list.add_child(button)

		button.focus_entered.connect(_on_button_focused.bind(button, quest))
		button.focus_next = play_button.get_path()
		button.focus_previous = play_button.get_path()

		if previous_button:
			button.focus_neighbor_top = previous_button.get_path()
			previous_button.focus_neighbor_bottom = button.get_path()
		else:
			button.grab_focus()

		previous_button = button

	previous_button.focus_neighbor_bottom = previous_button.get_path()


func _on_button_focused(button: Button, quest: Quest) -> void:
	play_button.focus_next = button.get_path()
	play_button.focus_previous = button.get_path()
	play_button.focus_neighbor_left = button.get_path()
	_selected_quest = quest

	if quest == STORY_QUEST_TEMPLATE:
		title.text = "StoryQuest Template"
		description.text = "This is the template for your own StoryQuests."
		authors.text = "A story by the Threadbare Authors"
		return

	title.text = quest.title

	if quest.description:
		description.text = quest.description
	else:
		description.text = "It is a mystery"

	match quest.authors.size():
		0:
			authors.text = "An anonymous story"
		1:
			authors.text = "A story by " + quest.authors[0]
		_:
			authors.text = (
				" "
				. join(
					[
						"A story by",
						", ".join(quest.authors.slice(0, -1)),
						"and",
						quest.authors[-1],
					]
				)
			)

	if quest.affiliation:
		authors.text += " of " + quest.affiliation


func _on_play_button_pressed() -> void:
	play.emit(_selected_quest)
