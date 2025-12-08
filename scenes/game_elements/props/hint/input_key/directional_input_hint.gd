# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var devices: InputHintManager = preload("uid://c1beocky1qjxi")

var _unpressed: Texture2D
var _up: Texture2D
var _down: Texture2D
var _left: Texture2D
var _right: Texture2D


func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)
	# Initialize with the current device reported by InputHelper
	_on_input_device_changed(InputHelper.device, InputHelper.device_index)


func _on_input_device_changed(_device: String, _device_index: int) -> void:
	# Refresh the displayed texture based on the device type
	_unpressed = devices.get_texture_for(InputHelper.device, "move_unpressed")
	_up = devices.get_texture_for(InputHelper.device, "move_up")
	_down = devices.get_texture_for(InputHelper.device, "move_down")
	_left = devices.get_texture_for(InputHelper.device, "move_left")
	_right = devices.get_texture_for(InputHelper.device, "move_right")


func _process(_delta: float) -> void:
	# Show the texture corresponding to the currently-pressed movement direction
	if Input.is_action_pressed("move_up"):
		texture = _up
	elif Input.is_action_pressed("move_down"):
		texture = _down
	elif Input.is_action_pressed("move_left"):
		texture = _left
	elif Input.is_action_pressed("move_right"):
		texture = _right
	else:
		# If no direction is pressed, show the unpressed
		texture = _unpressed
