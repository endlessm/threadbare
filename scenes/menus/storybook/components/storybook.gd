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
@export var quests_per_page: int = 8:
	set(value):
		quests_per_page = value
		quests_per_spread = value * 2

var quests_per_spread: int = 16

var _current_spread_index: int = -1
var _navigation_locked: bool = false
var _current_list_page: int = 0

# Node References
@onready var left_quest_list: VBoxContainer = %LeftQuestList
@onready var right_quest_list: VBoxContainer = %RightQuestList

@onready var quest_container: ScrollContainer = %QuestContainer
@onready var storybook_page: StorybookPage = %StorybookPage
@onready var back_button: Button = %BackButton
@onready var animated_book: AnimatedSprite2D = %AnimatedSprite2D
@onready var ui_container: Control = %StoryBookContent


func _ready() -> void:
	animated_book.animation_finished.connect(_on_animation_finished)
	_populate_quest_lists()


## Clears and regenerates the quest buttons based on the current page view
func _populate_quest_lists() -> void:
	#Clear out any existing buttons from previous views
	for child in left_quest_list.get_children():
		child.queue_free()
	for child in right_quest_list.get_children():
		child.queue_free()

	#Calculate the quest slices for this specific book spread
	var left_start: int = _current_list_page * quests_per_spread
	var left_end: int = left_start + quests_per_page
	var right_start: int = left_end
	var right_end: int = right_start + quests_per_page

	var previous_button: Button = null

	# Building the left page
	for i in range(left_start, min(left_end, quests.size())):
		previous_button = _create_quest_button(i, left_quest_list, previous_button)

	#Building the right page
	for i in range(right_start, min(right_end, quests.size())):
		previous_button = _create_quest_button(i, right_quest_list, previous_button)

	#Connect UI Focus back to the back button safely
	if previous_button:
		previous_button.focus_neighbor_bottom = back_button.get_path()
		back_button.focus_neighbor_top = previous_button.get_path()

	reset_focus()


## Method to build individual buttons (StoryQuests) and manage the focus chains
func _create_quest_button(
	quest_index: int, parent_container: VBoxContainer, prev_btn: Button
) -> Button:
	var quest: Quest = quests[quest_index]
	var button := Button.new()
	button.text = quest.get_title()
	button.theme_type_variation = "FlatButton"
	parent_container.add_child(button)
	button.set_meta("quest_index", quest_index)

	button.pressed.connect(_on_quest_button_pressed.bind(button))
	button.focus_next = back_button.get_path()
	button.focus_entered.connect(quest_container.ensure_control_visible.bind(button))

	if prev_btn:
		button.focus_neighbor_top = prev_btn.get_path()
		prev_btn.focus_neighbor_bottom = button.get_path()

	return button


## Show/hide index or detail pages
func _update_page_visibility() -> void:
	if _current_spread_index == 0:
		quest_container.visible = true
		storybook_page.visible = false

		# Grab focus on the first visible item of the left page
		if left_quest_list.get_child_count() > 0:
			var first_button: Button = left_quest_list.get_child(0)
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

	# If we are on the main index, turn pages back inside the list
	if _current_spread_index == 0 and _current_list_page > 0:
		_current_list_page -= 1
		animated_book.play("book_left")
		ui_container.visible = false
		await animated_book.animation_finished
		_populate_quest_lists()
		return

	_switch_to_page(_current_spread_index - 1)


func _on_right_button_pressed() -> void:
	if _navigation_locked:
		return

	# If we are on the main index, check if there are more quests to reveal on a new page
	if _current_spread_index == 0:
		var max_visible_so_far: int = (_current_list_page + 1) * quests_per_spread
		if quests.size() > max_visible_so_far:
			_current_list_page += 1
			animated_book.play("book_right")
			ui_container.visible = false
			await animated_book.animation_finished
			_populate_quest_lists()
			return

	_switch_to_page(_current_spread_index + 1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
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
