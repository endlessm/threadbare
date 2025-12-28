# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var keyboard_texture: Texture2D
@export var xbox_controller_texture: Texture2D
@export var playstation_controller_texture: Texture2D
@export var nintendo_controller_texture: Texture2D
@export var steam_controller_texture: Texture2D


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed(action_name):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE


func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)
	_on_input_device_changed(InputHelper.device, InputHelper.device_index)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	visible = true  # Always visible (hybrid)

	match device:
		InputHelper.DEVICE_KEYBOARD:
			if keyboard_texture:
				texture = keyboard_texture

		InputHelper.DEVICE_XBOX_CONTROLLER:
			texture = xbox_controller_texture

		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			texture = playstation_controller_texture

		InputHelper.DEVICE_SWITCH_CONTROLLER:
			texture = nintendo_controller_texture

		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			texture = steam_controller_texture

		_:
			texture = xbox_controller_texture
