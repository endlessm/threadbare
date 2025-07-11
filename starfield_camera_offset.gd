# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var camera: Camera2D


func _process(_delta: float) -> void:
	print(get_viewport().canvas_transform)

	(get_parent().material as ShaderMaterial).set_shader_parameter(
		"camera_pos", get_viewport().canvas_transform.origin
	)
