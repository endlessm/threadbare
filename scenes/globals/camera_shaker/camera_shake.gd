# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@onready var shaker: Shaker = %Shaker


func shake() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	shaker.target = camera
	shaker.shake()
