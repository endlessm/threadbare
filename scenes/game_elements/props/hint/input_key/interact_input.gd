# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

@export var action_name: StringName
@export var alternative: bool = false
@export var devices: InputHintManager


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
	var textures := devices.device_map[InputHelper.device]
	if alternative:
		texture = textures.get(action_name + "_alt")
		visible = texture != null
	else:
		texture = textures.get(action_name)
		visible = true
