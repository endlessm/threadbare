# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_prefix := &"move":
	set = _set_action_prefix
@export var devices: InputDeviceTextures = preload("uid://dptr7n813wvqd")

var _unpressed_action: StringName
var _up_action: StringName
var _down_action: StringName
var _left_action: StringName
var _right_action: StringName

var _textures: DirectionalInputTextures


func _ready() -> void:
	action_prefix = action_prefix

	InputHelper.device_changed.connect(_on_input_device_changed)


func _on_input_device_changed(_device: String, _device_index: int) -> void:
	_refresh_textures()


func _set_action_prefix(new_prefix: StringName) -> void:
	action_prefix = new_prefix
	_unpressed_action = action_prefix + "_unpressed"
	_up_action = action_prefix + "_up"
	_down_action = action_prefix + "_down"
	_left_action = action_prefix + "_left"
	_right_action = action_prefix + "_right"

	if not is_node_ready():
		return

	_refresh_textures()


func _refresh_textures() -> void:
	if InputHelper.device == InputHelper.DEVICE_KEYBOARD:
		_set_keyboard()
	else:
		_set_joypad()


func _set_keyboard() -> void:
	var right_event := InputHelper.get_keyboard_input_for_action(action_prefix + "_right")
	if right_event.physical_keycode != Key.KEY_RIGHT:
		push_warning("Expected arrow keys as primary binding")
	else:
		_textures = devices.keyboard.arrow_keys


func _set_joypad() -> void:
	var joypad: JoypadTextures = devices.joypads[InputHelper.device]

	var right_event := InputHelper.get_joypad_input_for_action(action_prefix + "_right")
	if right_event is InputEventJoypadMotion:
		match right_event.axis:
			JOY_AXIS_LEFT_X:
				_textures = joypad.left_stick
			JOY_AXIS_RIGHT_X:
				_textures = joypad.right_stick
			_:
				push_warning("Unexpected binding for ", action_prefix, right_event)
	elif right_event is InputEventJoypadButton:
		if right_event.button_index == JOY_BUTTON_DPAD_RIGHT:
			_textures = joypad.dpad
		else:
			push_warning("Unexpected binding for ", action_prefix, right_event)


func _process(_delta: float) -> void:
	if Input.is_action_pressed(_up_action):
		texture = _textures.up
	elif Input.is_action_pressed(_down_action):
		texture = _textures.down
	elif Input.is_action_pressed(_left_action):
		texture = _textures.left
	elif Input.is_action_pressed(_right_action):
		texture = _textures.right
	else:
		texture = _textures.unpressed
