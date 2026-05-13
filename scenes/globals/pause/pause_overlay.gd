# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@export_file("*.tscn") var title_scene: String
@export_file("*.tscn") var frays_end: String

@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var options: Control = %Options
@onready var abandon_quest_button: Button = %AbandonQuestButton
@onready var skip_tutorial_button: Button = %SkipTutorialButton


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var new_state := not get_tree().paused
	visible = new_state
	get_tree().paused = new_state

	Input.set_default_cursor_shape(Input.CURSOR_ARROW if new_state else Input.CURSOR_CROSS)

	if new_state:
		if not GameState.current_quest:
			skip_tutorial_button.hide()
			abandon_quest_button.hide()
		elif GameState.current_quest.skippable:
			skip_tutorial_button.show()
			abandon_quest_button.hide()
		else:
			skip_tutorial_button.hide()
			abandon_quest_button.show()
		pause_menu.show()
		resume_button.grab_focus()


func _on_abandon_quest_pressed() -> void:
	toggle_pause()
	GameState.abandon_quest()
	SceneSwitcher.change_to_file_with_transition(
		frays_end, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _on_skip_tutorial_pressed() -> void:
	toggle_pause()
	for ability: Enums.PlayerAbilities in GameState.current_quest.skip_abilities:
		GameState.set_ability(ability, true)
	GameState.mark_quest_completed()
	SceneSwitcher.change_to_file_with_transition(
		frays_end, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _on_options_button_pressed() -> void:
	options.show()


func _on_options_back() -> void:
	pause_menu.show()
	resume_button.grab_focus()


func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_title_screen_button_pressed() -> void:
	toggle_pause()
	SceneSwitcher.change_to_file_with_transition(
		title_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
