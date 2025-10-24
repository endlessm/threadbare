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
		var is_pressed = Input.is_action_pressed(action_name)
		var any_direction_pressed = (
			Input.is_action_pressed("ui_up")
			or Input.is_action_pressed("ui_down")
			or Input.is_action_pressed("ui_left")
			or Input.is_action_pressed("ui_right")
		)

		if is_pressed:
			visible = true
			modulate = Color.WHITE
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
			modulate = Color.WHITE
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
	_detect_initial_device()


func _detect_initial_device():
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		var device_id = joypads[0]
		var joy_name = Input.get_joy_name(device_id).to_lower()

		if joy_name.find("xbox") != -1:
			_on_input_device_changed(InputHelper.DEVICE_XBOX_CONTROLLER, device_id)
		elif joy_name.find("sony") != -1 or joy_name.find("ps") != -1:
			_on_input_device_changed(InputHelper.DEVICE_PLAYSTATION_CONTROLLER, device_id)
		elif joy_name.find("nintendo") != -1 or joy_name.find("switch") != -1:
			_on_input_device_changed(InputHelper.DEVICE_SWITCH_CONTROLLER, device_id)
		elif joy_name.find("steam") != -1:
			_on_input_device_changed(InputHelper.DEVICE_STEAMDECK_CONTROLLER, device_id)
		else:
			_on_input_device_changed(InputHelper.DEVICE_XBOX_CONTROLLER, device_id)  # fallback
	else:
		_on_input_device_changed(InputHelper.DEVICE_KEYBOARD, 0)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	current_device = device

	match device:
		InputHelper.DEVICE_KEYBOARD:
			is_keyboard_mode = true
			if is_controller_main_display:
				visible = false
			else:
				visible = false

		InputHelper.DEVICE_XBOX_CONTROLLER:
			is_keyboard_mode = false
			if is_controller_main_display:
				visible = true
				texture = xbox_controller_texture

		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			is_keyboard_mode = false
			if is_controller_main_display:
				visible = true
				texture = playstation_controller_texture

		InputHelper.DEVICE_SWITCH_CONTROLLER:
			is_keyboard_mode = false
			if is_controller_main_display:
				visible = true
				texture = nintendo_controller_texture

		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			is_keyboard_mode = false
			if is_controller_main_display:
				visible = true
				texture = steam_controller_texture
