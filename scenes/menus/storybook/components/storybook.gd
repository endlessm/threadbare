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

enum ContentTab { TOC, EN, ES, QUESTS }

## Quests to show in the storybook.
@export var quests: Array[Quest]
@export var quests_per_page: int = 7
@export var fade_duration: float = 0.15

var _current_spread_index: int
var _navigation_locked: bool = false

var _quests_per_language: Dictionary[String, Array] = {}
var _bookmark_indexes: Dictionary[ContentTab, int] = {}
var _show_language_bookmarks: bool

@onready var left_quest_list: VBoxContainer = %LeftQuestList
@onready var right_quest_list: VBoxContainer = %RightQuestList

@onready var quest_container: ScrollContainer = %QuestContainer
@onready var storybook_page: StorybookPage = %StorybookPage
@onready var back_button: Button = %BackButton
@onready var animated_book: AnimatedSprite2D = %AnimatedSprite2D
@onready var ui_container: Control = %StoryBookContent

# Bookmark button references
@onready var toc_bookmark_button: Button = %TOCBookmark
@onready var en_bookmark_button: Button = %ENBookmark
@onready var es_bookmark_button: Button = %ESBookmark


func _fade_out_ui() -> void:
	var tween := create_tween()
	tween.tween_property(ui_container, "modulate:a", 0.0, fade_duration)
	await tween.finished
	ui_container.visible = false


func _fade_in_ui() -> void:
	ui_container.visible = true
	var tween := create_tween()
	tween.tween_property(ui_container, "modulate:a", 1.0, fade_duration)


func _ready() -> void:
	animated_book.animation_finished.connect(_on_animation_finished)

	_quests_per_language = {}
	for q in quests:
		# If language is not defined, assume English:
		var language: String = q.language if q.language else "en"
		if language not in _quests_per_language:
			_quests_per_language[language] = [q]
		else:
			_quests_per_language[language].append(q)

	# Only show language bookmarks if there are quests for both English and Spanish, which are the
	# existing bookmarks so far.
	_show_language_bookmarks = "en" in _quests_per_language and "es" in _quests_per_language

	var last_index := 0
	_bookmark_indexes[ContentTab.TOC] = last_index
	if _show_language_bookmarks:
		_bookmark_indexes[ContentTab.EN] = (
			last_index + ceil(quests.size() / float(quests_per_page * 2))
		)
		last_index = _bookmark_indexes[ContentTab.EN]
		_bookmark_indexes[ContentTab.ES] = (
			last_index
			+ ceil(_quests_per_language.get("en", []).size() / float(quests_per_page * 2))
		)
		last_index = _bookmark_indexes[ContentTab.ES]
		_bookmark_indexes[ContentTab.QUESTS] = (
			last_index
			+ ceil(_quests_per_language.get("es", []).size() / float(quests_per_page * 2))
		)
	else:
		_bookmark_indexes[ContentTab.QUESTS] = (
			last_index + ceil(quests.size() / float(quests_per_page * 2))
		)

	toc_bookmark_button.pressed.connect(_switch_to_bookmark.bind(ContentTab.TOC))
	en_bookmark_button.pressed.connect(_switch_to_bookmark.bind(ContentTab.EN))
	es_bookmark_button.pressed.connect(_switch_to_bookmark.bind(ContentTab.ES))

	en_bookmark_button.visible = _show_language_bookmarks
	es_bookmark_button.visible = _show_language_bookmarks

	_update_page_visibility()


func _clear_list(quest_list: Node) -> void:
	for child: Node in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()


# Clears and regenerates the quest buttons based on the current page view
func _populate_quest_lists() -> void:
	_clear_list(left_quest_list)
	_clear_list(right_quest_list)

	var content_quests: Array[Quest]
	var spread_index: int

	if not _show_language_bookmarks or _current_spread_index < _bookmark_indexes[ContentTab.EN]:
		spread_index = _current_spread_index - _bookmark_indexes[ContentTab.TOC]
		content_quests.assign(quests)
	elif _current_spread_index < _bookmark_indexes[ContentTab.ES]:
		spread_index = _current_spread_index - _bookmark_indexes[ContentTab.EN]
		content_quests.assign(_quests_per_language.get("en", []))
	elif _current_spread_index < _bookmark_indexes[ContentTab.QUESTS]:
		spread_index = _current_spread_index - _bookmark_indexes[ContentTab.ES]
		content_quests.assign(_quests_per_language.get("es", []))

	var start := spread_index * quests_per_page * 2
	var end := start + quests_per_page * 2
	var spread_quests: Array[Quest] = content_quests.slice(start, end)

	var previous_button: Button = null

	for q: Quest in spread_quests.slice(0, quests_per_page):
		previous_button = _create_quest_button(q, left_quest_list, previous_button)

	for q: Quest in spread_quests.slice(quests_per_page):
		previous_button = _create_quest_button(q, right_quest_list, previous_button)

	# If the right page is empty, add a blank Control spacer so it maintains its width
	if right_quest_list.get_child_count() == 0:
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.x = 500
		right_quest_list.add_child(spacer)

	#Connect UI Focus back to the back button safely
	if previous_button:
		previous_button.focus_neighbor_bottom = back_button.get_path()
		back_button.focus_neighbor_top = previous_button.get_path()


## Method to build individual buttons (StoryQuests) and manage the focus chains
func _create_quest_button(
	quest: Quest, parent_container: VBoxContainer, prev_btn: Button
) -> Button:
	var button := Button.new()
	button.text = quest.get_title()
	button.theme_type_variation = "FlatButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	if quest in GameState.global.completed_quests:
		button.icon = button.get_theme_icon("checked", "CheckBox")
	else:
		button.icon = button.get_theme_icon("unchecked", "CheckBox")
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	parent_container.add_child(button)
	button.set_meta("quest", quest)

	button.pressed.connect(_on_quest_button_pressed.bind(button))
	button.focus_next = back_button.get_path()
	button.focus_entered.connect(quest_container.ensure_control_visible.bind(button))

	if prev_btn:
		button.focus_neighbor_top = prev_btn.get_path()
		prev_btn.focus_neighbor_bottom = button.get_path()

	return button


## Show/hide index or detail pages
func _update_page_visibility() -> void:
	if _current_spread_index < _bookmark_indexes[ContentTab.QUESTS]:
		quest_container.visible = true
		storybook_page.visible = false

		_populate_quest_lists()

		# Grab focus on the first visible item of the left page
		if left_quest_list.get_child_count() > 0:
			var first_button: Button = left_quest_list.get_child(0)
			if first_button and is_instance_valid(first_button) and not first_button.has_focus():
				first_button.grab_focus()
	else:
		quest_container.visible = false
		storybook_page.visible = true

		var quest_index := _current_spread_index - _bookmark_indexes[ContentTab.QUESTS]
		if quest_index >= 0 and quest_index < quests.size():
			var quest := quests[quest_index]
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

	if spread_index == _current_spread_index:
		return

	var total_spreads: int = _bookmark_indexes[ContentTab.QUESTS] + quests.size() - 1
	if spread_index < 0 or spread_index > total_spreads:
		return

	_navigation_locked = true

	var old_index := _current_spread_index
	_current_spread_index = spread_index

	await _fade_out_ui()

	if spread_index > old_index:
		animated_book.play("book_right")
	else:
		animated_book.play("book_left")
	ui_container.visible = false


func _on_animation_finished() -> void:
	_fade_in_ui()
	_update_page_visibility()
	_navigation_locked = false


func _on_left_button_pressed() -> void:
	_switch_to_page(_current_spread_index - 1)


func _on_right_button_pressed() -> void:
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
	var quest: Quest = button.get_meta("quest")
	var quest_index := quests.find(quest)
	_switch_to_page(_bookmark_indexes[ContentTab.QUESTS] + quest_index)


func _on_storybook_page_selected(quest: Quest, restart: bool) -> void:
	selected.emit(quest, restart)


func _on_back_button_pressed() -> void:
	selected.emit(null, false)


func _switch_to_bookmark(target_tab: ContentTab) -> void:
	_switch_to_page(_bookmark_indexes[target_tab])
