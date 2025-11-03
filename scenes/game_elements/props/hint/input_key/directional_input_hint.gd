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
# Fallback controller image when platform-specific one is not provided.
@export var controller_default_texture: Texture2D

# --- Controller pressed variants ---
# Textures shown when the controller button is pressed.
@export var controller_pressed_texture: Texture2D
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
	# If it exists, connect to its device change signal and initialize state.
	# If not present, we fall back to a simple keyboard-only assumption.
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
		# If a keyboard texture is assigned, show it and update its pressed visual.
		if keyboard_texture:
			visible = true
			if is_pressed:
				# If a pressed variant exists, use it. Otherwise simulate a "pressed" look
				# by using the normal texture and darkening the modulation.
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
			# No keyboard asset available: hide this node
			#(alternatively you could show a controller fallback).
			visible = false

		# We've handled keyboard mode entirely, return early.
		return

	# ---- CONTROLLER MODE ----
	# The following logic only runs when we are not in keyboard mode.
	if is_controller_main_display:
		# If the bound action is pressed,
		#show a pressed controller texture (platform-specific if available).
		if is_pressed:
			visible = true
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
					# Default pressed controller texture
					texture = controller_pressed_texture

		# If no directional input is pressed, show the idle (not pressed) controller texture.
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
					# Default controller image when platform-specific asset is missing.
					texture = controller_default_texture
		else:
			# If the player is using directional input (e.g. moving), hide the controller action icon.
			visible = false
	else:
		# If controller visuals are not the main display, hide the node.
		visible = false


func _on_input_device_changed(device: String, _device_index: int) -> void:
	# Called when InputHelper (or fallback) notifies us of a device change.
	current_device = device

	# Determine whether we should be in keyboard mode.
	# Prefer the InputHelper constant if available; otherwise compare the device string.
	if Engine.has_singleton("InputHelper"):
		# InputHelper.DEVICE_KEYBOARD should be defined by the addon.
		is_keyboard_mode = (device == InputHelper.DEVICE_KEYBOARD)
	else:
		# Fallback: check if the device string equals "keyboard" (case-insensitive).
		is_keyboard_mode = device.to_lower() == "keyboard"

	# Immediately refresh visuals to reflect the new device mode.
	_update_visual_state()


func _update_visual_state() -> void:
	# Force a visual refresh according to the current input mode and device.
	if is_keyboard_mode:
		# Keyboard mode: show keyboard texture if assigned, otherwise hide.
		if keyboard_texture:
			visible = true
			texture = keyboard_texture
			modulate = Color.WHITE
		else:
			visible = false
	else:
		# Controller mode: if controllers are enabled as the main display,
		#pick the correct idle texture.
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
					# Fallback controller texture when the device
					#is unknown or unsupported.
					texture = controller_default_texture
		else:
			# Controller visuals are not the primary display: hide the node.
			visible = false
