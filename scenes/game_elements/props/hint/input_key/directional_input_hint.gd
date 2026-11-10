# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_prefix := &"move":
	set = _set_action_prefix
@export var devices: InputDeviceTextures = preload("uid://dptr7n813wvqd")

## If true, when playing with keyboard + mouse, show mouse movement instead of
## the direction keys, because the mouse is what does the job. For example,
## aiming. See [member Settings.keyboard_only].
@export var follows_mouse: bool = false

var _unpressed_action: StringName
var _up_action: StringName
var _down_action: StringName
var _left_action: StringName
var _right_action: StringName

var _textures: DirectionalInputTextures

## The same mouse movement texture for every direction.
var _mouse_textures: DirectionalInputTextures


func _ready() -> void:
	action_prefix = action_prefix

	InputHelper.device_changed.connect(_on_input_device_changed)
	Settings.keyboard_only_changed.connect(_refresh_textures)


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
	if follows_mouse and not Settings.keyboard_only:
		_textures = _get_mouse_textures()
		return

	var right_event := InputHelper.get_keyboard_input_for_action(action_prefix + "_right")
	if right_event.physical_keycode != Key.KEY_RIGHT:
		push_warning("Expected arrow keys as primary binding")
	else:
		_textures = devices.keyboard.arrow_keys


func _get_mouse_textures() -> DirectionalInputTextures:
	if not _mouse_textures:
		var mouse_move := devices.keyboard.mouse_move
		_mouse_textures = DirectionalInputTextures.new()
		_mouse_textures.unpressed = mouse_move
		_mouse_textures.up = mouse_move
		_mouse_textures.down = mouse_move
		_mouse_textures.left = mouse_move
		_mouse_textures.right = mouse_move
	return _mouse_textures


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
