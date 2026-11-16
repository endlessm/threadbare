# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

signal puzzle_estatuas_completado

@export var objetivos: Array[SwitchEstatuaObjetivo] = []

var _completado: bool = false


func _ready() -> void:
	_conectar_switches()
	_evaluar_estado()


func _conectar_switches() -> void:
	var switches_node := get_node_or_null("Switches")
	if not switches_node:
		return
	for child in switches_node.get_children():
		if child and child.has_signal("estado_cambiado"):
			child.connect("estado_cambiado", Callable(self, "_on_switch_estado_cambiado"))


func _on_switch_estado_cambiado(_presionado: bool) -> void:
	call_deferred("_evaluar_estado")


func _evaluar_estado() -> void:
	if _completado:
		return
	if objetivos.is_empty():
		return

	for objetivo in objetivos:
		if not objetivo:
			return
		var estatua := get_node_or_null(objetivo.estatua_path)
		if not estatua or not estatua.has_method("obtener_direccion_actual"):
			return

		var direccion_actual: int = estatua.call("obtener_direccion_actual")
		var direccion_objetivo: int = _nombre_a_direccion(objetivo.direccion)
		if direccion_actual != direccion_objetivo:
			return

	_completado = true
	print("%s: ¡Puzzle de estatuas completado!" % name)
	puzzle_estatuas_completado.emit()


func _nombre_a_direccion(nombre: String) -> int:
	var lower := nombre.to_lower()
	match lower:
		"up", "arriba":
			return EstatuaPuzzle.Direction.UP
		"right", "derecha":
			return EstatuaPuzzle.Direction.RIGHT
		"left", "izquierda":
			return EstatuaPuzzle.Direction.LEFT
		_:
			return EstatuaPuzzle.Direction.DOWN

