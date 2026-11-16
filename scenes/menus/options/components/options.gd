# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

signal back

@export var back_button: Button


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

	back_button.pressed.connect(_on_back_button_pressed)


func _on_visibility_changed() -> void:
	if visible and back_button:
		back_button.grab_focus()


func _on_back_button_pressed() -> void:
	back.emit()
