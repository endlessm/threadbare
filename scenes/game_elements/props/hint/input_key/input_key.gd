# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed(action_name):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE

func _ready() -> void:
	InputHelper.device_changed.connect(_on_input_device_changed)


func _on_input_device_changed(device: String, device_index: int) -> void:
	print("XBox? ", device == InputHelper.DEVICE_XBOX_CONTROLLER)
	print("Device index? ", device_index) # Probably 0
