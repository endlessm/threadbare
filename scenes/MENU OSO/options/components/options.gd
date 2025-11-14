# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CenterContainer

signal back

@onready var back_button: Button = %BackButton


func _ready() -> void:
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if visible and back_button:
		back_button.grab_focus()


func _on_back_button_pressed() -> void:
	back.emit()
