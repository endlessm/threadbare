# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var camara = $"../Camera2D"
@onready var jugador = $"../Player"

func _process(delta):

	var ancho = get_viewport_rect().size.x

	var borde_derecho = camara.global_position.x + (ancho * 0.5) - 60
	var borde_izquierdo = camara.global_position.x - (ancho * 0.5) + 60

	if jugador.global_position.x > borde_derecho:
		jugador.global_position.x = borde_derecho

	if jugador.global_position.x < borde_izquierdo:
		jugador.global_position.x = borde_izquierdo
