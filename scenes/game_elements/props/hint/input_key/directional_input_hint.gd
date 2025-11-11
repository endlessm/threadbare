# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

# The input action this icon represents (e.g. "ui_accept").
@export var action_name: StringName = "ui_accept"

# --- Keyboard (unified image) ---
# Texture to show for keyboard input (normal and pressed variants).
@export var keyboard_texture: Texture2D
@export var keyboard_pressed_texture: Texture2D

# --- Controller textures (normal / not pressed) ---
# Platform-specific controller button images.
@export var xbox_controller_texture: Texture2D
@export var playstation_controller_texture: Texture2D
@export var nintendo_controller_texture: Texture2D
@export var steam_controller_texture: Texture2D

# --- Controller pressed variants ---
# Textures shown when the controller button is pressed.
@export var xbox_pressed_texture: Texture2D
@export var playstation_pressed_texture: Texture2D
@export var nintendo_pressed_texture: Texture2D
@export var steam_pressed_texture: Texture2D

# When true, this node will show controller visuals as the main display
# (used when we want controller images to be shown instead of keyboard).
@export var is_controller_main_display: bool = false

# Runtime state:
var current_device: String = ""  # current input device identifier (e.g. "keyboard", "xbox")
var is_keyboard_mode: bool = true  # whether we are currently showing keyboard visuals


func _ready() -> void:
	# Attempt to use the project's InputHelper singleton (Threadbare addon).
	if Engine.has_singleton("InputHelper"):
		# Connect our handler so we update visuals whenever the input device changes.
		InputHelper.device_changed.connect(_on_input_device_changed)
		# Initialize visual state based on current InputHelper values.
		_on_input_device_changed(InputHelper.device, InputHelper.device_index)
	else:
		# Simple fallback: treat the starting device as keyboard.
		_on_input_device_changed("keyboard", -1)


func _physics_process(_delta: float) -> void:
	# Check whether the action for this icon is being pressed right now.
	var is_pressed := Input.is_action_pressed(action_name)

	# Also check if any directional input is being pressed
	# (used to hide controller icon while moving).
	var any_direction_pressed := (
		Input.is_action_pressed("move_up")
		or Input.is_action_pressed("move_down")
		or Input.is_action_pressed("move_left")
		or Input.is_action_pressed("move_right")
	)

	# ---- KEYBOARD MODE ----
	if is_keyboard_mode:
		if keyboard_texture:
			visible = true
			if is_pressed:
				if keyboard_pressed_texture:
					texture = keyboard_pressed_texture
					modulate = Color.WHITE
				else:
					# No explicit pressed texture -> reuse keyboard texture and darken it.
					texture = keyboard_texture
					modulate = Color(0.7, 0.7, 0.7)
			else:
				# Not pressed: normal keyboard texture and default modulation.
				texture = keyboard_texture
				modulate = Color.WHITE
		else:
			visible = false
		return

	# ---- CONTROLLER MODE ----
	if is_controller_main_display:
		if is_pressed:
			visible = true
			# Assign platform-specific pressed texture directly.
			match current_device:
				InputHelper.DEVICE_XBOX_CONTROLLER:
					texture = xbox_pressed_texture
				InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
					texture = playstation_pressed_texture
				InputHelper.DEVICE_SWITCH_CONTROLLER:
					texture = nintendo_pressed_texture
				InputHelper.DEVICE_STEAMDECK_CONTROLLER:
					texture = steam_pressed_texture
				_:
					# leave texture as null for now; we will apply a fallback below
					texture = null

			# Final pressed texture fallback: prefer Xbox pressed, then Steam pressed.
			if not texture:
				texture = xbox_pressed_texture if xbox_pressed_texture else steam_pressed_texture

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
					texture = null

			if not texture:
				# Fallback controller image (prefer Xbox, then Steam)
				texture = (
					xbox_controller_texture if xbox_controller_texture else steam_controller_texture
				)

		else:
			visible = false
	else:
		visible = false


func _on_input_device_changed(device: String, _device_index: int) -> void:
	current_device = device

	if Engine.has_singleton("InputHelper"):
		is_keyboard_mode = (device == InputHelper.DEVICE_KEYBOARD)
	else:
		is_keyboard_mode = device.to_lower() == "keyboard"

	_update_visual_state()


func _update_visual_state() -> void:
	if is_keyboard_mode:
		if keyboard_texture:
			visible = true
			texture = keyboard_texture
			modulate = Color.WHITE
		else:
			visible = false
	else:
		if is_controller_main_display:
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
					texture = (
						xbox_controller_texture
						if xbox_controller_texture
						else steam_controller_texture
					)
		else:
			visible = false
