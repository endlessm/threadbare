# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

var is_on: bool = false

func turn_on() -> void:
	is_on = true
	print("TURN ON REAL:", get_path(), " · visible=", visible)
	$Sprite2D.self_modulate = Color(3, 3, 3)


# opcional: método para apagar
func turn_off() -> void:
	if not is_on:
		return
	is_on = false
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.6, 0.6, 0.6) # apagado (fallback)
