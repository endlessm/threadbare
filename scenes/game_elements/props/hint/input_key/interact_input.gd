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
			# Modo teclado: cambiar color
			modulate = Color.GRAY
		else:
			# Modo controlador: solo ajustar color, sin textura pressed
			modulate = Color.GRAY
	else:
		# Estado normal
		modulate = Color.WHITE


func _ready() -> void:
	print("Interact node ready: ", name)
	InputHelper.device_changed.connect(_on_input_device_changed)
	_detect_initial_device()


func _detect_initial_device():
	var joy_count = Input.get_connected_joypads().size()
	if joy_count > 0:
		_on_input_device_changed(InputHelper.DEVICE_XBOX_CONTROLLER, 0)
	else:
		_on_input_device_changed(InputHelper.DEVICE_KEYBOARD, 0)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	print("Interact node - Device detected: ", device)
	current_device = device
	visible = true  # Siempre visible (híbrido)

	match device:
		InputHelper.DEVICE_KEYBOARD:
			is_keyboard_mode = true
			if keyboard_texture:
				texture = keyboard_texture
				print("Interact showing keyboard texture")

		InputHelper.DEVICE_XBOX_CONTROLLER:
			is_keyboard_mode = false
			texture = xbox_controller_texture
			print("Interact showing Xbox texture")

		InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
			is_keyboard_mode = false
			texture = playstation_controller_texture
			print("Interact showing PlayStation texture")

		InputHelper.DEVICE_SWITCH_CONTROLLER:
			is_keyboard_mode = false
			texture = nintendo_controller_texture
			print("Interact showing Nintendo texture")

		InputHelper.DEVICE_STEAMDECK_CONTROLLER:
			is_keyboard_mode = false
			texture = steam_controller_texture
			print("Interact showing Steam texture")
