# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

const TITLE_SCENE: PackedScene = preload("uid://stdqc6ttomff")
const FRAYS_END := "uid://cufkthb25mpxy"

@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var options: Control = %Options
@onready var abandon_quest_button: Button = %AbandonQuestButton


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

	if new_state:
		abandon_quest_button.visible = GameState.is_on_quest()
		pause_menu.show()
		resume_button.grab_focus()


func _on_abandon_quest_pressed() -> void:
	toggle_pause()
	GameState.abandon_quest()
	SceneSwitcher.change_to_file_with_transition(
		FRAYS_END, ^"", Transition.Effect.FADE, Transition.Effect.FADE
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
	SceneSwitcher.change_to_packed_with_transition(
		TITLE_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
