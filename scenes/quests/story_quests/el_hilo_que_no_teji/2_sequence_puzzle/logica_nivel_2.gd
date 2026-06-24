# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

static var puente1_listo: bool = false
static var puente2_listo: bool = false
static var puente3_listo: bool = false

# EL ESCUDO QUE FALTABA
var nivel_apagandose: bool = false

func _ready() -> void:
	# 1. Preparamos el escudo para cuando Lino muera
	nivel_apagandose = false
	self.tree_exiting.connect(_activar_escudo)

	# 2. Ocultamos los puentes sanos al inicio
	if has_node("TileMapLayers/Puente1"): $TileMapLayers/Puente1.hide()
	if has_node("TileMapLayers/Puente2"): $TileMapLayers/Puente2.hide()
	if has_node("TileMapLayers/Puente3"): $TileMapLayers/Puente3.hide()
	
	# 3. Revisamos la Memoria: Restaura solo el puente correcto
	if puente1_listo: _restaurar_puente_y_borrar_hilo(1)
	if puente2_listo: _restaurar_puente_y_borrar_hilo(2)
	if puente3_listo: _restaurar_puente_y_borrar_hilo(3)

# Se activa una fracción de segundo antes de que la escena se reinicie
func _activar_escudo() -> void:
	nivel_apagandose = true

# =========================================================
# FUNCIONES PARA REPARAR LOS PUENTES (Señales de los hilos)
# =========================================================

func reparar_puente_1() -> void:
	if nivel_apagandose: return # <-- El escudo bloquea el falso positivo al morir
	puente1_listo = true
	if has_node("TileMapLayers/Puente1"): $TileMapLayers/Puente1.show()
	if has_node("TileMapLayers/PuenteRoto1"): $TileMapLayers/PuenteRoto1.queue_free()

func reparar_puente_2() -> void:
	if nivel_apagandose: return
	puente2_listo = true
	if has_node("TileMapLayers/Puente2"): $TileMapLayers/Puente2.show()
	if has_node("TileMapLayers/PuenteRoto2"): $TileMapLayers/PuenteRoto2.queue_free()

func reparar_puente_3() -> void:
	if nivel_apagandose: return
	puente3_listo = true
	if has_node("TileMapLayers/Puente3"): $TileMapLayers/Puente3.show()
	if has_node("TileMapLayers/PuenteRoto3"): $TileMapLayers/PuenteRoto3.queue_free()

func reparar_puente2() -> void:
	pass 

# =========================================================
# LÓGICA INTERNA DE RESTAURACIÓN (Para el Checkpoint)
# =========================================================

func _restaurar_puente_y_borrar_hilo(numero: int) -> void:
	# 1. Restaurar puentes
	if has_node("TileMapLayers/Puente" + str(numero)): 
		get_node("TileMapLayers/Puente" + str(numero)).show()
	if has_node("TileMapLayers/PuenteRoto" + str(numero)): 
		get_node("TileMapLayers/PuenteRoto" + str(numero)).queue_free()
		
	# 2. Borrar hilo
	var coleccionable = get_node_or_null("CollectibleItem" + str(numero))
	if coleccionable: 
		if coleccionable.has_signal("tree_exited"):
			for conexion in coleccionable.tree_exited.get_connections():
				coleccionable.tree_exited.disconnect(conexion.callable)
		coleccionable.queue_free()

	# 3. ---> CORRECCIÓN: RUTA EXACTA PARA PRENDER EL FUEGO <---
	var ruta_letrero = "OnTheGround/Puzzle_Isla" + str(numero) + "/Hints/SequencePuzzleHintSign" + str(numero)
	var letrero = get_node_or_null(ruta_letrero)
	
	if letrero:
		letrero.is_solved = true 
		if "animated_sprite" in letrero and letrero.animated_sprite != null:
			letrero.animated_sprite.play("solved")
	else:
		print("ATENCIÓN: No se encontró el letrero en la ruta: ", ruta_letrero)			
