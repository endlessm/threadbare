# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

#var arboles_contactados: int = 0
#const ARBOLES_NECESARIOS := 3

#func _ready() -> void:
	## Busca en TODO el árbol de la escena, recursivamente, nodos de tipo ArbolFantasma1
	#var arboles: Array = get_tree().get_root().find_children("*", "ArbolFantasma1", true, false)
	#var conectados := 0
	#for a in arboles:
		## Evita conexiones duplicadas
		#if not a.dialogo_terminado.is_connected(reportar_arbol_contactado):
			#a.dialogo_terminado.connect(reportar_arbol_contactado)
			#conectados += 1
	#print("[Outro] Árboles ArbolFantasma1 encontrados:", arboles.size(), " | Conectados ahora:", conectados)
#
#func reportar_arbol_contactado() -> void:
	#arboles_contactados += 1
	#print("[Outro] Progreso árboles: ", arboles_contactados, "/", ARBOLES_NECESARIOS)
	#if arboles_contactados >= ARBOLES_NECESARIOS:
		#abrir_camino()
#
#func abrir_camino() -> void:
	#var obstaculos := get_tree().get_nodes_in_group("bloqueo_camino")
	#print("[Outro] Meta alcanzada. Obstáculos encontrados en 'bloqueo_camino': ", obstaculos.size())
	#for o in obstaculos:
		#o.queue_free()
	#print("[Outro] Camino abierto.")
