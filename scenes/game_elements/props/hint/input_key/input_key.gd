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

func _on_input_device_changed(device: String, device_index: int) -> void:
	print("Device detected: ", device)
	print("Device index: ", device_index)
	
	match device:
		InputHelper.DEVICE_KEYBOARD:
			if keyboard_texture:
				texture = keyboard_texture
				print("Changed to keyboard texture")
		InputHelper.DEVICE_XBOX_CONTROLLER:
			if xbox_controller_texture:
				texture = xbox_controller_texture
				print("Changed to Xbox controller texture")
		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			if playstation_controller_texture:
				texture = playstation_controller_texture
				print("Changed to PlayStation controller texture")
		InputHelper.DEVICE_NINTENDO_CONTROLLER:
			if nintendo_controller_texture:
				texture = nintendo_controller_texture
				print("Changed to Nintendo controller texture")
		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			if steam_controller_texture:
				texture = steam_controller_texture
				print("Changed to Steam Deck controller texture")
		_:
			print("Unknown device detected: ", device)
