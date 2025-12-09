# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_prefix := &"move":
	set = _set_action_prefix

@export var devices: InputHintManager = preload("uid://c1beocky1qjxi")

var _unpressed_action: StringName
var _up_action: StringName
var _down_action: StringName
var _left_action: StringName
var _right_action: StringName

var _unpressed: Texture2D
var _up: Texture2D
var _down: Texture2D
var _left: Texture2D
var _right: Texture2D


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
	var textures := devices.device_map[InputHelper.device]
	_unpressed = textures.get_direction(action_prefix, &"unpressed")
	_up = textures.get_direction(action_prefix, &"up")
	_down = textures.get_direction(action_prefix, &"down")
	_left = textures.get_direction(action_prefix, &"left")
	_right = textures.get_direction(action_prefix, &"right")


func _process(_delta: float) -> void:
	if Input.is_action_pressed(_up_action):
		texture = _up
	elif Input.is_action_pressed(_down_action):
		texture = _down
	elif Input.is_action_pressed(_left_action):
		texture = _left
	elif Input.is_action_pressed(_right_action):
		texture = _right
	else:
		texture = _unpressed
