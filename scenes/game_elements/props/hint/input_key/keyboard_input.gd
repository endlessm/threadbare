# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var keyboard_texture: Texture2D

var is_keyboard_active: bool = false


func _physics_process(_delta: float) -> void:
	if not is_keyboard_active or not visible:
		return

	if Input.is_action_pressed(action_name):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE


func _ready() -> void:
	print("Keyboard node ready: ", name, " - Action: ", action_name)
	InputHelper.device_changed.connect(_on_input_device_changed)
	_initialize_device_state()


func _initialize_device_state() -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		var device_id = joypads[0]
		var joy_name = Input.get_joy_name(device_id).to_lower()
		print("Detected joypad on start (keyboard node): ", joy_name)

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
	print("Keyboard node - Device detected: ", device, " - Node: ", name)

	match device:
		InputHelper.DEVICE_KEYBOARD:
			_activate_keyboard()
		_:
			_deactivate_keyboard()


func _activate_keyboard() -> void:
	is_keyboard_active = true
	visible = true
	modulate = Color.WHITE

	if keyboard_texture:
		texture = keyboard_texture
		print("Showing keyboard texture for: ", name)


func _deactivate_keyboard() -> void:
	is_keyboard_active = false
	visible = false
	print("Hiding keyboard node: ", name)
