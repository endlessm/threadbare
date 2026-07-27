# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

signal dismissed


func _ready() -> void:
	if _should_show_touchscreen_warning():
		show()


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


func _on_dismiss_button_pressed() -> void:
	dismissed.emit()
