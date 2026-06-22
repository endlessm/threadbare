# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var cantidad_requerida: int = 4
@export var hilo_collectible: CollectibleItem

var _recolectados: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_connect_pergaminos()


func _connect_pergaminos() -> void:
	for pergamino: Node in get_tree().get_nodes_in_group(&"pergaminos"):
		if pergamino.has_signal(&"recolectado") and not pergamino.recolectado.is_connected(_on_pergamino_recolectado):
			pergamino.recolectado.connect(_on_pergamino_recolectado)


func _on_pergamino_recolectado() -> void:
	_recolectados += 1
	if _recolectados >= cantidad_requerida and hilo_collectible and not hilo_collectible.revealed:
		hilo_collectible.reveal()
