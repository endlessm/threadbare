# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Shows the mouse cursor only where the mouse can be used.
##
## The cursor is hidden by default. Screens where the mouse can be used, like
## menus and dialogues, call [method hold] when they appear and [method release]
## when they go away. While held, the cursor appears when the mouse moves, and
## hides again after a few seconds without movement.

const MOUSE_CURSOR_DEFAULT = preload("uid://cee2juvnxco6c")
const MOUSE_CURSOR_CROSS = preload("uid://bx11wyx7unc4q")

## How many times [method hold] was called without a matching [method release].
## A count rather than a boolean, so that if two screens hold the mouse and one
## goes away, the mouse stays usable for the other.
var _holds: int = 0

@onready var hide_timer: Timer = %HideTimer


func _ready() -> void:
	Input.set_custom_mouse_cursor(MOUSE_CURSOR_DEFAULT, Input.CURSOR_ARROW, Vector2(0, 0))
	Input.set_custom_mouse_cursor(MOUSE_CURSOR_CROSS, Input.CURSOR_CROSS, Vector2(32, 32))
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

	# Hidden until something holds the mouse and the player moves it.
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


## Allow showing the mouse cursor, because the mouse can be used. Call
## [method release] when it can't be used anymore. Each call to this needs a
## matching call to [method release].
func hold() -> void:
	_holds += 1


## Undo a previous [method hold]. When nothing holds the mouse anymore, the cursor
## is hidden.
func release() -> void:
	if _holds == 0:
		push_warning("MouseManager.release() called without a matching hold()")
		return
	_holds -= 1
	if _holds == 0:
		_hide_mouse()


func _input(event: InputEvent) -> void:
	# Only show the cursor for a real mouse, not for the mouse motion that Godot
	# emulates from touch.
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if _holds > 0:
			_show_mouse()


func _show_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hide_timer.start()


func _hide_mouse() -> void:
	hide_timer.stop()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_hide_timer_timeout() -> void:
	_hide_mouse()


func _on_dialogue_started(_resource: DialogueResource) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	hold()


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	release()
