# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## Placa de presión: cuando una caja del grupo "pushable_box" queda ENCIMA, "abre"
## sus [member gates] (p. ej. el portón de la escalera) para dejar pasar al jugador.
## Al quitar la caja, se vuelven a cerrar. Emite [signal pressed].
##
## No toca archivos base. Detecta solo cajas (filtra por grupo), así que aunque su
## máscara incluya la capa de muros, los muros estáticos no la activan.

signal pressed(is_on: bool)

## Nodos a abrir cuando hay una caja encima. Si tienen un método [code]set_open(bool)[/code]
## se llama; si son [StaticBody2D] se les desactiva la colisión y se ocultan
## (revelando la escalera que tapaban).
@export var gates: Array[Node2D] = []

@onready var visual: Polygon2D = $Visual

var _boxes_on: int = 0
var is_on: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply(false)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"pushable_box"):
		_boxes_on += 1
		if not is_on:
			_set_pressed(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"pushable_box"):
		_boxes_on = max(0, _boxes_on - 1)
		if _boxes_on == 0 and is_on:
			_set_pressed(false)


func _set_pressed(value: bool) -> void:
	is_on = value
	_apply(value)
	pressed.emit(value)


func _apply(value: bool) -> void:
	if is_instance_valid(visual):
		visual.color = Color(0.45, 0.9, 0.5) if value else Color(0.8, 0.8, 0.85)
	for gate in gates:
		if gate == null:
			continue
		if gate.has_method(&"set_open"):
			gate.call(&"set_open", value)
		elif gate is StaticBody2D:
			(gate as StaticBody2D).set_deferred(&"collision_layer", 0 if value else 16)
			gate.visible = not value
