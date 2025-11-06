# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

# The action this icon represents (e.g., "move_up", "move_left", etc.)
@export var action_name: StringName = "move_unpressed"

# If true, shows controller icons instead of keyboard icons
@export var is_controller_main_display: bool = true

# Runtime state variables
var current_device: String = ""         
var is_keyboard_mode: bool = true


func _ready() -> void:
	# Try to connect to device change signals from InputHelper (if available)
	if Engine.has_singleton("InputHelper"):
		InputHelper.device_changed.connect(_on_input_device_changed)
		# Initialize with the current device reported by InputHelper
		_on_input_device_changed(InputHelper.device, InputHelper.device_index)
	else:
		# Fallback to keyboard if InputHelper is not available
		_on_input_device_changed("keyboard", -1)


func _on_input_device_changed(device: String, _device_index: int) -> void:
	# Update current input device
	current_device = device

	# Determine whether current device is a keyboard
	if Engine.has_singleton("InputHelper"):
		is_keyboard_mode = (device == InputHelper.DEVICE_KEYBOARD)
	else:
		is_keyboard_mode = device.to_lower() == "keyboard"

	# Refresh the displayed texture based on the device type
	_update_texture()


func _physics_process(_delta: float) -> void:
	# Check which movement direction (if any) is currently pressed
	var pressed_dir := ""   
	if Input.is_action_pressed("move_up"):
		pressed_dir = "move_up"
	elif Input.is_action_pressed("move_down"):
		pressed_dir = "move_down"
	elif Input.is_action_pressed("move_left"):
		pressed_dir = "move_left"
	elif Input.is_action_pressed("move_right"):
		pressed_dir = "move_right"

	# If nothing is pressed -> show the idle hint (move_unpressed)
	if pressed_dir == "":
		# If this node is the idle node, ensure it's visible and has its texture
		if String(action_name) == "move_unpressed":
			_update_texture()
			if texture:
				visible = true
			else:
				visible = false
		else:
			# Not the idle node: hide
			visible = false
	else:
		# There is a direction pressed: only the corresponding node should be visible
		if pressed_dir == action_name:
			_update_texture()
			if texture:
				visible = true
			else:
				visible = false
		else:
			visible = false

	# Visual feedback when the actual action (e.g., move_up) is pressed
	if Input.is_action_pressed(action_name):
		# subtle pressed look
		modulate = Color(0.994, 0.99, 0.992, 1.0)
	else:
		modulate = Color.WHITE


func _update_texture() -> void:
	# Obtener la textura desde el AutoLoad InputGlobal
	var tex: Texture2D = InputGlobal.get_texture_for(current_device, action_name)

	# Fallback: si no hay textura específica, usa "move_unpressed"
	if tex == null and action_name != "move_unpressed":
		tex = InputGlobal.get_texture_for(current_device, "move_unpressed")

	# Aplicar o esconder
	if tex:
		texture = tex
		visible = true
	else:
		visible = false
