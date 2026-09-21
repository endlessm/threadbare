# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal mode_changed

const MOUSE_CURSOR_DEFAULT = preload("uid://cee2juvnxco6c")
const MOUSE_CURSOR_CROSS = preload("uid://bx11wyx7unc4q")

## Conteo de referencias para controlar cuándo está permitida la interacción con ratón.
var _holds: int = 0

@onready var hide_timer: Timer = %HideTimer


func _ready() -> void:
	Input.set_custom_mouse_cursor(MOUSE_CURSOR_DEFAULT, Input.CURSOR_ARROW, Vector2(0, 0))
	Input.set_custom_mouse_cursor(MOUSE_CURSOR_CROSS, Input.CURSOR_CROSS, Vector2(32, 32))
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

	# El cursor comienza oculto hasta que un sistema solicite un hold y se mueva el ratón.
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


## Registra una solicitud para habilitar la interacción con el ratón.
func hold() -> void:
	_holds += 1


## Libera una solicitud previa de interacción con el ratón.
func release() -> void:
	_holds = maxi(0, _holds - 1)
	if _holds == 0:
		_hide_mouse()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _holds > 0:
			_show_mouse()
	elif _is_keyboard_or_controller_event(event):
		_hide_mouse()


func _is_keyboard_or_controller_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.is_pressed():
		return true
	if event is InputEventJoypadButton and event.is_pressed():
		return true
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		return true
	return false


func _show_mouse() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mode_changed.emit()
	hide_timer.start()


func _hide_mouse() -> void:
	hide_timer.stop()
	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		mode_changed.emit()


func _on_hide_timer_timeout() -> void:
	_hide_mouse()


func _on_dialogue_started(_resource: DialogueResource) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	hold()


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	release()
