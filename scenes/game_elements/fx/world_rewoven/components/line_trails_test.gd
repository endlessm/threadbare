# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var mouse_tracker: Node2D = %MouseTracker
@onready var curly_mouse: CurlyTrail = %CurlyMouse
@onready var stitch_mouse: StitchTrail = %StitchMouse


func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	mouse_tracker.global_position = lerp(mouse_tracker.global_position, mouse_pos, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	if event.pressed:
		curly_mouse.process_mode = Node.PROCESS_MODE_DISABLED
		curly_mouse.visible = false
		stitch_mouse.process_mode = Node.PROCESS_MODE_INHERIT
		stitch_mouse.visible = true
	else:
		curly_mouse.process_mode = Node.PROCESS_MODE_INHERIT
		curly_mouse.visible = true
		curly_mouse.wheel_rotation *= -1
		stitch_mouse.process_mode = Node.PROCESS_MODE_DISABLED
		stitch_mouse.visible = false
