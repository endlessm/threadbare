# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var options: Control = %Options


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
		pause_menu.show()
		resume_button.grab_focus()


func _on_options_button_pressed() -> void:
	options.show()


func _on_options_back() -> void:
	pause_menu.show()
	resume_button.grab_focus()


func _on_resume_button_pressed() -> void:
	toggle_pause()
