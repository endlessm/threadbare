# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

var posiciones_iniciales: Array[Vector2]
func _ready() -> void:
	pass  # Replace with function body.

func guardar_posiciones_iniciales()->void:
	##llamar a la funcion despues que se haya creado este nodo
	for i in get_children():
		posiciones_iniciales.append(i.global_position)

func mover_a_posiciones_iniciales()->void:
	var j = 0
	for i in get_children():
		i.global_position = posiciones_iniciales[j]		
		j += 1
func mostrar_secuaces()->void:
	for i in get_children():
		i.visible = true		
