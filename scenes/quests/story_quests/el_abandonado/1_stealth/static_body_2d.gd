# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

@onready var camara = $"../Camera2D"

func _process(delta):
	var ancho = get_viewport_rect().size.x

	global_position = Vector2(
		camara.global_position.x + (ancho * 0.5),
		camara.global_position.y
	)
