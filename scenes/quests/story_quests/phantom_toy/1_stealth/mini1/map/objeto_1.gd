# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
var jugador_cerca := false

func _on_body_entered(body):
	if body is Player:
		jugador_cerca = true

func _on_body_exited(body):
	if body is Player:
		jugador_cerca = false


func _input_event(_viewport, event, _shape_idx):
	if not jugador_cerca:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_parent().recoger_objeto()
			queue_free()
