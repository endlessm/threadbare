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

var _current_page_index: int = -1
var _navigation_locked: bool = false

@onready var quest_list: VBoxContainer = %QuestList
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

	var previous_button: Button = null
	for quest in _enumerate_quests():
		var button := Button.new()
		button.text = quest.get_title()
		button.theme_type_variation = "FlatButton"
		quest_list.add_child(button)
		button.set_meta("quest", quest)

		button.focus_entered.connect(_on_button_focused.bind(button, quest))
		button.focus_next = back_button.get_path()
		button.focus_previous = storybook_page.play_button.get_path()

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


func _switch_to_page(page_index: int) -> void:
	if _navigation_locked:
		return

	var total := quest_list.get_child_count()
	if total == 0:
		return
	if page_index < 0 or page_index >= total:
		return
	if page_index == _current_page_index:
		return

	_navigation_locked = true

	var button: Button = quest_list.get_child(page_index)
	if not is_instance_valid(button):
		_navigation_locked = false
		return

	var quest: Quest = button.get_meta("quest") if button.has_meta("quest") else null

	back_button.focus_previous = button.get_path()
	storybook_page.play_button.focus_next = button.get_path()
	storybook_page.play_button.focus_neighbor_left = button.get_path()
	if quest:
		storybook_page.quest = quest

	if _current_page_index != -1:
		if page_index > _current_page_index:
			animated_book.play("book_right")
		else:
			animated_book.play("book_left")
		ui_container.visible = false
	else:
		if not button.has_focus():
			button.grab_focus()
		_navigation_locked = false

	_current_page_index = page_index


func _on_animation_finished() -> void:
	_navigation_locked = false
	ui_container.visible = true

	var button: Button = quest_list.get_child(_current_page_index)
	if button and is_instance_valid(button) and not button.has_focus():
		button.grab_focus()


func _on_left_button_pressed() -> void:
	if _navigation_locked:
		return
	var target := _current_page_index - 1
	if target < 0:
		target = max(0, quest_list.get_child_count() - 1)
	_switch_to_page(target)


func _on_right_button_pressed() -> void:
	if _navigation_locked:
		return
	var target := _current_page_index + 1
	if target >= quest_list.get_child_count():
		target = 0
	_switch_to_page(target)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		# Go back
		get_viewport().set_input_as_handled()
		selected.emit(null)


func _on_button_focused(button: Button, _quest: Quest) -> void:
	if _navigation_locked:
		return
	var current_index: int = quest_list.get_children().find(button)
	if current_index == -1:
		return
	_switch_to_page(current_index)


func _on_storybook_page_selected(quest: Quest) -> void:
	selected.emit(quest)


func _on_back_button_pressed() -> void:
	selected.emit(null)


func reset_focus() -> void:
	if quest_list and quest_list.get_child_count() > 0:
		_switch_to_page(0)
