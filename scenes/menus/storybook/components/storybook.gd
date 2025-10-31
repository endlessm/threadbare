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

var _quests: Array[Quest] = []
var _current_spread_index: int = -1
var _navigation_locked: bool = false

@onready var quest_list: VBoxContainer = %QuestList
@onready var quest_container: Control = %QuestContainer
@onready var storybook_page: StorybookPage = %StorybookPage
@onready var back_button: Button = %BackButton
@onready var animated_book: AnimatedSprite2D = %AnimatedSprite2D
@onready var ui_container: Control = %StoryBookContent
@onready var left_button: Button = %Left_Button
@onready var right_button: Button = %Right_Button


func _enumerate_quests() -> Array[Quest]:
	var has_template: bool = false
	var quests: Array[Quest] = []

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
	animated_book.animation_finished.connect(_on_animation_finished)

	_quests = _enumerate_quests()

	var previous_button: Button = null
	for i in _quests.size():
		var quest: Quest = _quests[i]
		var button := Button.new()
		button.text = quest.get_title()
		button.theme_type_variation = "FlatButton"
		quest_list.add_child(button)
		button.set_meta("quest_index", i)

		button.pressed.connect(_on_quest_button_pressed.bind(button))
		button.focus_next = back_button.get_path()

		if previous_button:
			button.focus_neighbor_top = previous_button.get_path()
			previous_button.focus_neighbor_bottom = button.get_path()

		previous_button = button

	if previous_button:
		previous_button.focus_neighbor_bottom = back_button.get_path()
		back_button.focus_neighbor_top = previous_button.get_path()

	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)

	reset_focus()


## Show/hide index or detail pages
func _update_page_visibility() -> void:
	if _current_spread_index == 0:
		quest_container.visible = true
		storybook_page.visible = false

		if quest_list.get_child_count() > 0:
			var first_button: Button = quest_list.get_child(0)
			if first_button and is_instance_valid(first_button) and not first_button.has_focus():
				first_button.grab_focus()
	else:
		quest_container.visible = false
		storybook_page.visible = true

		var quest_index: int = _current_spread_index - 1
		if quest_index >= 0 and quest_index < _quests.size():
			storybook_page.quest = _quests[quest_index]

			if storybook_page.play_button and is_instance_valid(storybook_page.play_button):
				if not storybook_page.play_button.has_focus():
					storybook_page.play_button.grab_focus()

			back_button.focus_previous = storybook_page.play_button.get_path()
			storybook_page.play_button.focus_next = back_button.get_path()
			storybook_page.play_button.focus_neighbor_left = back_button.get_path()


func _switch_to_page(spread_index: int) -> void:
	if _navigation_locked:
		return

	var total_spreads: int = _quests.size() + 1
	if total_spreads <= 1:
		return

	if spread_index < 0:
		spread_index = total_spreads - 1
	if spread_index >= total_spreads:
		spread_index = 0

	if spread_index == _current_spread_index:
		return

	_navigation_locked = true
	var old_index: int = _current_spread_index
	_current_spread_index = spread_index

	if old_index != -1:
		if spread_index > old_index or (spread_index == 0 and old_index == total_spreads - 1):
			animated_book.play("book_right")
		else:
			animated_book.play("book_left")
		ui_container.visible = false

	else:
		_update_page_visibility()
		_navigation_locked = false


func _on_animation_finished() -> void:
	_navigation_locked = false
	ui_container.visible = true

	_update_page_visibility()


func _on_left_button_pressed() -> void:
	if _navigation_locked:
		return
	_switch_to_page(_current_spread_index - 1)


func _on_right_button_pressed() -> void:
	if _navigation_locked:
		return
	_switch_to_page(_current_spread_index + 1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		# Go back
		get_viewport().set_input_as_handled()
		selected.emit(null)


func _on_quest_button_pressed(button: Button) -> void:
	if not button.has_meta("quest_index"):
		return

	var quest_index: int = button.get_meta("quest_index")
	_switch_to_page(quest_index + 1)


func _on_storybook_page_selected(quest: Quest) -> void:
	selected.emit(quest)


func _on_back_button_pressed() -> void:
	selected.emit(null)


func reset_focus() -> void:
	_switch_to_page(0)
