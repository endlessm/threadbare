# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const MOUSE_CURSOR_CROSS = preload("uid://bx11wyx7unc4q")

@onready var hide_timer: Timer = %HideTimer


func _ready() -> void:
	Input.set_custom_mouse_cursor(MOUSE_CURSOR_CROSS, Input.CURSOR_CROSS, Vector2(32, 32))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hide_timer.start(3)


func _on_hide_timer_timeout() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
