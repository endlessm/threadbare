# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

func _ready() -> void:
	# Asegurarnos de que los puentes sanos nazcan invisibles
	if has_node("TileMapLayers/Puente1"): $TileMapLayers/Puente1.hide()
	if has_node("TileMapLayers/Puente2"): $TileMapLayers/Puente2.hide()
	if has_node("TileMapLayers/Puente3"): $TileMapLayers/Puente3.hide()

# --- FUNCIONES PARA REPARAR LOS PUENTES (Llamadas por los hilos) ---
func reparar_puente_1() -> void:
	if has_node("TileMapLayers/Puente1"): $TileMapLayers/Puente1.show()
	if has_node("TileMapLayers/PuenteRoto1"): $TileMapLayers/PuenteRoto1.queue_free()

func reparar_puente_2() -> void:
	if has_node("TileMapLayers/Puente2"): $TileMapLayers/Puente2.show()
	if has_node("TileMapLayers/PuenteRoto2"): $TileMapLayers/PuenteRoto2.queue_free()

func reparar_puente_3() -> void:
	if has_node("TileMapLayers/Puente3"): $TileMapLayers/Puente3.show()
	if has_node("TileMapLayers/PuenteRoto3"): $TileMapLayers/PuenteRoto3.queue_free()


func reparar_puente2() -> void:
	pass # Replace with function body.
