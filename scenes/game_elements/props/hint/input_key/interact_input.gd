# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var alternative: bool = false

@export var devices: InputDeviceTextures = preload("uid://dptr7n813wvqd")


func _process(_delta: float) -> void:
	if Input.is_action_pressed(action_name):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE


func _ready() -> void:
	if devices:
		InputHelper.device_changed.connect(_on_input_device_changed)
		_on_input_device_changed(InputHelper.device, InputHelper.device_index)
	else:
		push_warning("%s: Per-device textures not configured" % get_path())


func _on_input_device_changed(device: String, _device_index: int) -> void:
	if device == InputHelper.DEVICE_KEYBOARD:
		if alternative:
			_set_mouse_texture()
		else:
			_set_keyboard_texture()
	else:
		_set_joypad_texture(device)

	visible = (device == InputHelper.DEVICE_KEYBOARD or not alternative)


func _set_joypad_texture(device: String) -> void:
	var textures := devices.joypads[device]
	var event := InputHelper.get_joypad_input_for_action(action_name)
	if event is InputEventJoypadButton:
		texture = textures.buttons.get(event.button_index)
	elif event is InputEventJoypadMotion:
		texture = textures.triggers.get(event.axis)

	if not texture:
		push_warning("No %s texture for %s %s" % [device, action_name, event])
		set_process(false)


func _set_keyboard_texture() -> void:
	var event := InputHelper.get_keyboard_input_for_action(action_name)
	if event is not InputEventKey:
		push_warning("Primary keyboard binding for %s not a key: %s" % [action_name, event])
		return

	if event.physical_keycode:
		# Try to show the logical label for physical mappings; i.e. on AZERTY
		# show W when the physical binding is for Z. As of Godot 4.6, this API
		# is only implemented on X11/Wayland/Mac/Windows; notably it is not
		# available on the Web port.
		if OS.has_feature("pc"):
			var logical_keycode := DisplayServer.keyboard_get_keycode_from_physical(
				event.physical_keycode
			)
			if logical_keycode and logical_keycode in devices.keyboard.keys:
				texture = devices.keyboard.keys[logical_keycode]
				return

		# If logical keycode not available or not in keys map, use physical_keycode
		if event.physical_keycode in devices.keyboard.keys:
			texture = devices.keyboard.keys[event.physical_keycode]
			return

	if event.keycode and event.keycode in devices.keyboard.keys:
		texture = devices.keyboard.keys[event.keycode]
		return

	push_warning("No keyboard texture for %s binding %s" % [action_name, event])


func _set_mouse_texture() -> void:
	for event: InputEvent in InputHelper.get_keyboard_inputs_for_action(action_name):
		if event is InputEventMouseButton:
			texture = devices.keyboard.mouse_buttons[event.button_index]
			return

	push_warning("No mouse binding for %s" % [action_name])
