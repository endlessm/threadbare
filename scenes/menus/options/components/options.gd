# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

## Emitted when this menu goes back to the previous (if any)
## through the [member back_button].
signal back

## The button to go back to the previous menu, if any.
@export var back_button: Button

## The default control to show when this menu becomes visible.
@export var default_page: Control


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

	back_button.pressed.connect(_on_back_button_pressed)


func _on_visibility_changed() -> void:
	if visible:
		if back_button:
			back_button.grab_focus()
		if default_page:
			default_page.show()


func _on_back_button_pressed() -> void:
	back.emit()
