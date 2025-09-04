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
	print("Script ready for action: ", action_name)
	print("Textures assigned:")
	print("  Keyboard: ", keyboard_texture != null)
	print("  Xbox: ", xbox_controller_texture != null)
	print("  PlayStation: ", playstation_controller_texture != null)
	print("  Nintendo: ", nintendo_controller_texture != null)
	print("  Steam: ", steam_controller_texture != null)

func _on_input_device_changed(device: String, device_index: int) -> void:
	print("=== DEVICE CHANGE DETECTED ===")
	print("Node: ", name)
	print("Action: ", action_name)
	print("Device detected: '", device, "'")
	print("Device index: ", device_index)
	print("Current texture before change: ", texture)
	
	match device:
		InputHelper.DEVICE_KEYBOARD:
			if keyboard_texture:
				texture = keyboard_texture
				print("✅ Changed to keyboard texture: ", keyboard_texture)
			else:
				print("❌ No keyboard texture assigned!")
		InputHelper.DEVICE_XBOX_CONTROLLER:
			if xbox_controller_texture:
				texture = xbox_controller_texture
				print("✅ Changed to Xbox controller texture: ", xbox_controller_texture)
			else:
				print("❌ No Xbox texture assigned!")
		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			if playstation_controller_texture:
				texture = playstation_controller_texture
				print("✅ Changed to PlayStation controller texture: ", playstation_controller_texture)
			else:
				print("❌ No PlayStation texture assigned!")
		InputHelper.DEVICE_NINTENDO_CONTROLLER:
			if nintendo_controller_texture:
				texture = nintendo_controller_texture
				print("✅ Changed to Nintendo controller texture: ", nintendo_controller_texture)
			else:
				print("❌ No Nintendo texture assigned!")
		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			if steam_controller_texture:
				texture = steam_controller_texture
				print("✅ Changed to Steam Deck controller texture: ", steam_controller_texture)
			else:
				print("❌ No Steam texture assigned!")
		_:
			print("❌ Unknown device detected: '", device, "'")
	
	print("Current texture after change: ", texture)
	print("===============================")
