# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends HBoxContainer

signal start_pressed
signal credits_pressed

@onready var button_box: VBoxContainer = %ButtonBox
@onready var start_button: Button = %StartButton


func _ready() -> void:
	# Wait for fade-in transition to finish before grabbing focus, so that the
	# start button does not appear interactive while input is blocked.
	if Transitions.is_running():
		await Transitions.finished

	_on_visibility_changed()


func _on_start_button_pressed() -> void:
	start_pressed.emit()


func _on_credits_button_pressed() -> void:
	credits_pressed.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_visibility_changed() -> void:
	if visible and start_button:
		start_button.grab_focus()
