# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var xbox_controller_texture: Texture2D
@export var playstation_controller_texture: Texture2D
@export var nintendo_controller_texture: Texture2D
@export var steam_controller_texture: Texture2D

@export var is_controller_main_display: bool = false
@export var controller_default_texture: Texture2D
@export var controller_pressed_texture: Texture2D

@export var xbox_pressed_texture: Texture2D
@export var playstation_pressed_texture: Texture2D
@export var nintendo_pressed_texture: Texture2D
@export var steam_pressed_texture: Texture2D

var current_device: String = ""
var is_keyboard_mode: bool = true


func _physics_process(_delta: float) -> void:
	if is_keyboard_mode:
		return

	if is_controller_main_display:
		var is_pressed := Input.is_action_pressed(action_name)
		var any_direction_pressed := (
			Input.is_action_pressed("move_up")
			or Input.is_action_pressed("move_down")
			or Input.is_action_pressed("move_left")
			or Input.is_action_pressed("move_right")
		)

		if is_pressed:
			visible = true
			match current_device:
				InputHelper.DEVICE_XBOX_CONTROLLER:
					texture = (
						xbox_pressed_texture if xbox_pressed_texture else controller_pressed_texture
					)
				InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
					texture = (
						playstation_pressed_texture
						if playstation_pressed_texture
						else controller_pressed_texture
					)
				InputHelper.DEVICE_SWITCH_CONTROLLER:
					texture = (
						nintendo_pressed_texture
						if nintendo_pressed_texture
						else controller_pressed_texture
					)
				InputHelper.DEVICE_STEAMDECK_CONTROLLER:
					texture = (
						steam_pressed_texture
						if steam_pressed_texture
						else controller_pressed_texture
					)
				_:
					texture = controller_pressed_texture
		elif not any_direction_pressed:
			visible = true
			match current_device:
				InputHelper.DEVICE_XBOX_CONTROLLER:
					texture = xbox_controller_texture
				InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
					texture = playstation_controller_texture
				InputHelper.DEVICE_SWITCH_CONTROLLER:
					texture = nintendo_controller_texture
				InputHelper.DEVICE_STEAMDECK_CONTROLLER:
					texture = steam_controller_texture
				_:
					texture = controller_default_texture
		else:
			visible = false


func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)
	_on_input_device_changed(InputHelper.device, InputHelper.device_index)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	current_device = device

	is_keyboard_mode = (device == InputHelper.DEVICE_KEYBOARD)
	match device:
		InputHelper.DEVICE_KEYBOARD:
			if is_controller_main_display:
				visible = false
			else:
				visible = false

		InputHelper.DEVICE_XBOX_CONTROLLER:
			if is_controller_main_display:
				visible = true
				texture = xbox_controller_texture

		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			if is_controller_main_display:
				visible = true
				texture = playstation_controller_texture

		InputHelper.DEVICE_SWITCH_CONTROLLER:
			if is_controller_main_display:
				visible = true
				texture = nintendo_controller_texture

		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			if is_controller_main_display:
				visible = true
				texture = steam_controller_texture

		_:
			if is_controller_main_display:
				visible = true
				texture = controller_default_texture
