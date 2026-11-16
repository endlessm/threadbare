# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var keyboard_texture: Texture2D
@export var xbox_controller_texture: Texture2D
@export var playstation_controller_texture: Texture2D
@export var nintendo_controller_texture: Texture2D
@export var steam_controller_texture: Texture2D

var current_device: String = ""
var is_keyboard_mode: bool = true


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed(action_name):
		if is_keyboard_mode:
			# Keyboard mode: change color
			modulate = Color.GRAY
		else:
			# Controller mode: only adjust color, without a "pressed" texture
			modulate = Color.GRAY
	else:
		# Normal state
		modulate = Color.WHITE


func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)
	_on_input_device_changed(InputHelper.device, InputHelper.device_index)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	current_device = device
	visible = true  # Always visible (hybrid)

	match device:
		InputHelper.DEVICE_KEYBOARD:
			is_keyboard_mode = true
			if keyboard_texture:
				texture = keyboard_texture

		InputHelper.DEVICE_XBOX_CONTROLLER:
			is_keyboard_mode = false
			texture = xbox_controller_texture

		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			is_keyboard_mode = false
			texture = playstation_controller_texture

		InputHelper.DEVICE_SWITCH_CONTROLLER:
			is_keyboard_mode = false
			texture = nintendo_controller_texture

		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			is_keyboard_mode = false
			texture = steam_controller_texture

		_:
			is_keyboard_mode = false
			texture = xbox_controller_texture
