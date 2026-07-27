# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var arbol_fantasma_1: CharacterBody2D = $ArbolFantasma1

var arboles_contactados: int = 0
const ARBOLES_NECESARIOS := 1


func _ready() -> void:
	arbol_fantasma_1.dialogo_terminado.connect(reportar_arbol_contactado)


func reportar_arbol_contactado() -> void:
	arboles_contactados += 1
	print("Progreso árboles: ", arboles_contactados, "/", ARBOLES_NECESARIOS)
	if arboles_contactados >= ARBOLES_NECESARIOS:
		abrir_camino()


func abrir_camino() -> void:
	var obstaculo1 = get_tree().get_nodes_in_group("bloqueo_camino1")
	print("Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino1': ", obstaculo1.size())
	if obstaculo1.size() > 0:
		obstaculo1[0].queue_free()
		print("Camino abierto.")
	else:
		print("No hay obstáculos para eliminar o ya fueron eliminados.")
