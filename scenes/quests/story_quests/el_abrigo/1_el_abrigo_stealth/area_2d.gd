# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):  # Asegúrate de que tu jugador esté en el grupo "player"
		print("🐑 ¡Jugador detectado!")
		# Hace que la oveja empiece a moverse
		var path_follower = get_parent().get_node("Path2D/PathFollow2D")
		path_follower.start_moving()
