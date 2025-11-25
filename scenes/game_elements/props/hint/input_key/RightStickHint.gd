# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName = ""

var current_device: String = ""
var is_keyboard_mode: bool = true


func _ready() -> void:
	if Engine.has_singleton("InputHelper"):
		InputHelper.device_changed.connect(_on_input_device_changed)
		_on_input_device_changed(InputHelper.device, InputHelper.device_index)
	else:
		_on_input_device_changed("keyboard", -1)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	current_device = device

	if Engine.has_singleton("InputHelper"):
		is_keyboard_mode = (device == InputHelper.DEVICE_KEYBOARD)
	else:
		is_keyboard_mode = device.to_lower() == "keyboard"

	_update_texture()


func _physics_process(_delta: float) -> void:
	var pressed_dir := ""

	if Input.is_action_pressed("aim_up"):
		pressed_dir = "aim_up"
	elif Input.is_action_pressed("aim_down"):
		pressed_dir = "aim_down"
	elif Input.is_action_pressed("aim_left"):
		pressed_dir = "aim_left"
	elif Input.is_action_pressed("aim_right"):
		pressed_dir = "aim_right"

	# --- si NO hay dirección presionada ---
	if pressed_dir == "":
		if action_name == "aim_unpressed":
			_update_texture()
			visible = texture != null
		else:
			visible = false
		return

	# --- si hay dirección presionada ---
	if pressed_dir == action_name:
		_update_texture()
		visible = texture != null
	else:
		visible = false

	# efecto visual
	if action_name != "aim_unpressed" and Input.is_action_pressed(action_name):
		modulate = Color(0.98, 0.98, 0.98)
	else:
		modulate = Color.WHITE


func _update_texture() -> void:
	var tex: Texture2D = RightStickHintManager.get_texture_for(current_device, action_name)

	if tex == null and action_name != "aim_unpressed":
		tex = RightStickHintManager.get_texture_for(current_device, "aim_unpressed")

	texture = tex
	visible = tex != null
