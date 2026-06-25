# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var dismiss_button: Button = $PanelContainer/VBoxContainer/DismissButton


func _ready() -> void:
	# Connecting the button click
	dismiss_button.pressed.connect(_on_dismiss_pressed)

	# Checking if the device works for the game
	if not _should_show_touchscreen_warning():
		# If their device is compatible, jump straight to the main menu
		_go_to_main_menu()


func _should_show_touchscreen_warning() -> bool:
	var has_touch: bool = DisplayServer.is_touchscreen_available()
	var has_keyboard: bool
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		# DisplayServer.has_hardware_keyboard() is not implemented on the web.
		# Assuming mobile web browsers don't have a hardware keyboard.
		has_keyboard = false
	else:
		has_keyboard = DisplayServer.has_hardware_keyboard()
	return has_touch and not has_keyboard


func _on_dismiss_pressed() -> void:
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	var pages_container: TabContainer = get_parent() as TabContainer

	if pages_container:
		# Tab 0 is this warning screen so tab 1 is the main menu scene right below it
		pages_container.current_tab = 1
