# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Storybook
extends CanvasLayer
## Offers a choice of quests by scanning a given [member quest_directory].

## Emitted when the player chooses a quest from the storybook, with
## [param restart] indicating whether the quest should be restarted
## ([code]true[/code]) or continued ([code]false[/code]) if it is in progress.
## When the player leaves the storybook without choosing a quest, emitted with
## [param quest] set to [code]null[/code].
signal selected(quest: Quest, restart: bool)

## Quests to show in the storybook.
@export var quests: Array[Quest]

var _current_spread_index: int = -1
var _navigation_locked: bool = false

@onready var quest_list: VBoxContainer = %QuestList
@onready var quest_container: Control = %QuestContainer
@onready var storybook_page: StorybookPage = %StorybookPage
@onready var back_button: Button = %BackButton
@onready var animated_book: AnimatedSprite2D = %AnimatedSprite2D
@onready var ui_container: Control = %StoryBookContent


func _ready() -> void:
	animated_book.animation_finished.connect(_on_animation_finished)

	var previous_button: Button = null
	for i in quests.size():
		var quest: Quest = quests[i]
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
		if quest_index >= 0 and quest_index < quests.size():
			var quest: Quest = quests[quest_index]
			storybook_page.quest = quest

			if storybook_page.play_button and is_instance_valid(storybook_page.play_button):
				if not storybook_page.play_button.has_focus():
					storybook_page.play_button.grab_focus()

			# TODO: move the back button into the page scene &
			# set the focus relationships in the inspector.
			back_button.focus_previous = storybook_page.play_button.get_path()
			storybook_page.play_button.focus_next = back_button.get_path()

			if storybook_page.restart_button.visible:
				back_button.focus_next = storybook_page.restart_button.get_path()
				back_button.focus_neighbor_right = storybook_page.restart_button.get_path()
				storybook_page.restart_button.focus_previous = back_button.get_path()
				storybook_page.restart_button.focus_neighbor_left = back_button.get_path()

				storybook_page.restart_button.focus_next = storybook_page.play_button.get_path()
				storybook_page.restart_button.focus_neighbor_right = (
					storybook_page.play_button.get_path()
				)
				storybook_page.play_button.focus_previous = storybook_page.restart_button.get_path()
				storybook_page.play_button.focus_neighbor_left = (
					storybook_page.restart_button.get_path()
				)
			else:
				back_button.focus_next = storybook_page.play_button.get_path()
				back_button.focus_neighbor_right = storybook_page.play_button.get_path()
				storybook_page.play_button.focus_neighbor_left = back_button.get_path()
				storybook_page.play_button.focus_previous = back_button.get_path()


func _switch_to_page(spread_index: int) -> void:
	if _navigation_locked:
		return

	var total_spreads: int = quests.size() + 1
	if total_spreads <= 1:
		return

	if spread_index < 0 or spread_index >= total_spreads:
		return

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
		selected.emit(null, false)
	elif event.is_action_pressed("next_tab"):
		_on_right_button_pressed()
	elif event.is_action_pressed("previous_tab"):
		_on_left_button_pressed()


func _on_quest_button_pressed(button: Button) -> void:
	if not button.has_meta("quest_index"):
		return

	var quest_index: int = button.get_meta("quest_index")
	_switch_to_page(quest_index + 1)


func _on_storybook_page_selected(quest: Quest, restart: bool) -> void:
	selected.emit(quest, restart)


func _on_back_button_pressed() -> void:
	selected.emit(null, false)


func reset_focus() -> void:
	_switch_to_page(0)
