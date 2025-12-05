# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@onready var hide_timer: Timer = %HideTimer


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hide_timer.start(3)


func _on_hide_timer_timeout() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
