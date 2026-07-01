# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var radio_max := 100.0
@export var velocidad := 40.0

var centro : Vector2
var direccion : Vector2

func _ready():

	randomize()

	centro = global_position

	direccion = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	$AnimatedSprite2D.play("idle")

func _process(delta):

	# Pequeños cambios aleatorios de dirección
	direccion += Vector2(
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2)
	) * delta

	direccion = direccion.normalized()

	global_position += direccion * velocidad * delta

	# Mantenerlas cerca del centro
	var distancia = global_position.distance_to(centro)

	if distancia > radio_max:

		var regreso = (centro - global_position).normalized()

		direccion = regreso
