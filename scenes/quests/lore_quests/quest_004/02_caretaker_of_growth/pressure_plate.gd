# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D
## Pressure plate: triggers [member gates] when a "pushable_box" is placed on top.
## Closes gates when the box is removed. Emits [signal pressed].

signal pressed(is_on: bool)

## Nodes to open/close when pressed. Calls set_open(bool) if available,
## or toggles collision/visibility if the gate is a StaticBody2D.
@export var gates: Array[Node2D] = []

var is_on: bool = false
var _boxes_on: int = 0

@onready var visual: Polygon2D = $Visual


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
