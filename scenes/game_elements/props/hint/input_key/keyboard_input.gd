# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var keyboard_texture: Texture2D

var is_keyboard_active: bool = false


func _physics_process(_delta: float) -> void:
	if not is_keyboard_active or not visible:
		return

	if Input.is_action_pressed(action_name):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE


func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)
	_on_input_device_changed(InputHelper.device, InputHelper.device_index)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	match device:
		InputHelper.DEVICE_KEYBOARD:
			_activate_keyboard()
		_:
			_deactivate_keyboard()


func _activate_keyboard() -> void:
	is_keyboard_active = true
	visible = true
	modulate = Color.WHITE

	if keyboard_texture:
		texture = keyboard_texture


func _deactivate_keyboard() -> void:
	is_keyboard_active = false
	visible = false
