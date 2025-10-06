# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var arbol_fantasma_3: CharacterBody2D = $ArbolFantasma3

var arboles_contactados: int = 0
const PREGUNTAS_NECESARIOS := 1


func _ready() -> void:
	arbol_fantasma_3.dialogo_terminado3.connect(reportar_arbol_contactado3)


func reportar_arbol_contactado3() -> void:
	arboles_contactados += 1
	print("Progreso árboles: ", arboles_contactados, "/", PREGUNTAS_NECESARIOS)
	if arboles_contactados >= PREGUNTAS_NECESARIOS:
		abrir_camino()


func abrir_camino() -> void:
	var obstaculo3 := get_tree().get_nodes_in_group("bloqueo_camino3")
	print("Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino3': ", obstaculo3.size())
	#for o in obstaculos:
	if obstaculo3.size() > 0:
		obstaculo3[0].queue_free()
		print("Camino abierto.")
	else:
		print("No hay obstáculos para eliminar o ya fueron eliminados.")


func _on_arbol_fantasma_3_dialogo_terminado_3() -> void:
	pass  # Replace with function body.
