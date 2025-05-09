# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@onready var shaker = %Shaker


func shake():
	var camera = get_viewport().get_camera_2d()
	shaker.target = camera
	shaker.shake()
