# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var arbol_fantasma_2: CharacterBody2D = $ArbolFantasma2

var arboles_contactados: int = 0
const PREGUNTAS_NECESARIOS := 1


func _ready() -> void:
	arbol_fantasma_2.dialogo_terminado2.connect(reportar_arbol_contactado2)


func reportar_arbol_contactado2() -> void:
	arboles_contactados += 1
	print("Progreso árboles: ", arboles_contactados, "/", PREGUNTAS_NECESARIOS)
	if arboles_contactados >= PREGUNTAS_NECESARIOS:
		abrir_camino()


func abrir_camino() -> void:
	var obstaculo2 := get_tree().get_nodes_in_group("bloqueo_camino2")
	print("Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino2': ", obstaculo2.size())
	if obstaculo2.size() > 0:
		obstaculo2[0].queue_free()
		print("Camino abierto.")
	else:
		print("No hay obstáculos para eliminar o ya fueron eliminados.")

func _on_arbol_fantasma_2_dialogo_terminado_2() -> void:
	pass  # Replace with function body.
