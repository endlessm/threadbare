# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BloqueoSaltoDialogo
extends Node
## Bloquea que el jugador adelante o salte el diálogo mientras este nodo esté en la escena.

const ACCIONES_BLOQUEADAS: Array[StringName] = [
	&"dialogue_next",
	&"dialogue_skip",
	&"ui_accept",
]


func _init(funciona_en_pausa: bool = false) -> void:
	if funciona_en_pausa:
		process_mode = Node.PROCESS_MODE_ALWAYS


## Con _input se procesa antes que la interfaz y el globo no recibe estas pulsaciones.
func _input(event: InputEvent) -> void:
	if _debe_bloquearse(event):
		get_viewport().set_input_as_handled()


func _debe_bloquearse(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	for accion in ACCIONES_BLOQUEADAS:
		if InputMap.has_action(accion) and event.is_action(accion):
			return true
	return false
