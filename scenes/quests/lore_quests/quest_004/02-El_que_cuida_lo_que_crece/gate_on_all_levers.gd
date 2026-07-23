# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Abre un objetivo (Door / cualquier Toggleable) SOLO cuando TODAS las palancas
## de la lista están encendidas. Para el puzzle "activa las 3 palancas para abrir
## el paso". Cuélgalo en la escena, asígnale las palancas y la puerta.

## Las palancas (nodos lever.tscn) que hay que encender todas.
@export var levers: Array[Node]
## El objetivo a abrir (un Door u otro Toggleable con set_toggled).
@export var target: Node


func _ready() -> void:
	for lever in levers:
		if lever and lever.has_signal(&"toggled"):
			lever.toggled.connect(_on_lever_toggled)
	_check()


func _on_lever_toggled(_is_on: bool) -> void:
	_check()


func _check() -> void:
	if not is_instance_valid(target) or not target.has_method("set_toggled"):
		return
	for lever in levers:
		if not is_instance_valid(lever) or not lever.is_on:
			target.set_toggled(false)
			return
	target.set_toggled(true)
