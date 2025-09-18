# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Storybook
extends Control
## Offers a choice of quests by scanning a given [member quest_directory].

## Emitted when the player chooses a quest; or leaves the storybook without choosing a quest, in
## which case [code]quest[/code] is [code]null[/code].
signal selected(quest: Quest)

## Template quest, which is expected to be blank and so is treated specially.
const STORY_QUEST_TEMPLATE: Quest = preload("uid://ddxn14xw66ud8")

## Replacement metadata for the template's blank metadata
const TEMPLATE_QUEST_METADATA: Quest = preload("uid://dwl8letaanhhi")

## Sprite frames for the template quest
const TEMPLATE_PLAYER_FRAMES: SpriteFrames = preload("uid://vwf8e1v8brdp")

## Animation for the template quest
const TEMPLATE_ANIMATION_NAME: StringName = &"idle"

const QUEST_RESOURCE_NAME := "quest.tres"

## Directory to scan for quests. This directory should have 1 or more subdirectories, each of which
## have a [code]quest.tres[/code] file within.
@export_dir var quest_directory: String = "res://scenes/quests/story_quests"

@onready var quest_list: VBoxContainer = %QuestList
@onready var storybook_page: StorybookPage = %StorybookPage
@onready var back_button: Button = %BackButton
@onready var animated_book: AnimatedTextureRect = %AnimatedTextureRect
@onready var ui_container: MarginContainer = %CenterContainer


var _last_focused_button: Button
var _last_focus_index: int = -1

func _enumerate_quests() -> Array[Quest]:
	var has_template: bool = false
	var quests: Array[Quest]

	for dir in ResourceLoader.list_directory(quest_directory):
		var quest_path := quest_directory.path_join(dir).path_join(QUEST_RESOURCE_NAME)
		if ResourceLoader.exists(quest_path):
			var quest: Quest = ResourceLoader.load(quest_path)
			if quest == STORY_QUEST_TEMPLATE:
				has_template = true
			else:
				quests.append(quest)

	if has_template:
		quests.append(TEMPLATE_QUEST_METADATA)

	return quests


func _ready() -> void:
	var previous_button: Button = null
	for quest in _enumerate_quests():
		var button := Button.new()
		button.text = quest.get_title()
		button.theme_type_variation = "FlatButton"
		quest_list.add_child(button)

		button.focus_entered.connect(_on_button_focused.bind(button, quest))
		button.focus_next = back_button.get_path()
		button.focus_previous = storybook_page.play_button.get_path()

		if previous_button:
			button.focus_neighbor_top = previous_button.get_path()
			previous_button.focus_neighbor_bottom = button.get_path()

		previous_button = button

	previous_button.focus_neighbor_bottom = back_button.get_path()
	back_button.focus_neighbor_top = previous_button.get_path()

	reset_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Go back
		get_viewport().set_input_as_handled()
		selected.emit(null)


func _on_button_focused(button: Button, quest: Quest) -> void:
	back_button.focus_previous = button.get_path()
	storybook_page.play_button.focus_next = button.get_path()
	storybook_page.play_button.focus_neighbor_left = button.get_path()
	storybook_page.quest = quest
	
	var current_index = quest_list.get_children().find(button)

	if _last_focus_index != -1:
		if current_index > _last_focus_index:
			animated_book.animation_name = "book_right"
			_hide_ui_temporarily(button)
		elif current_index < _last_focus_index:
			animated_book.animation_name = "book_left"
			_hide_ui_temporarily(button)

	_last_focus_index = current_index

	
func _hide_ui_temporarily(button: Button) -> void:
	ui_container.visible = false
	await get_tree().create_timer(0.2).timeout
	ui_container.visible = true
	if is_instance_valid(button):
		button.grab_focus()



func _on_storybook_page_selected(quest: Quest) -> void:
	selected.emit(quest)


func _on_back_button_pressed() -> void:
	selected.emit(null)


func reset_focus() -> void:
	if quest_list and quest_list.get_child_count() > 0:
		quest_list.get_child(0).grab_focus()
