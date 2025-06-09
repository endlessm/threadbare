# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends VBoxContainer

@onready var check_button: CheckButton = %CheckButton


func _ready() -> void:
	check_button.set_pressed_no_signal(Settings.is_fullscreen())


func _on_check_button_toggled(toggled_on: bool) -> void:
	Settings.toggle_fullscreen(toggled_on)
