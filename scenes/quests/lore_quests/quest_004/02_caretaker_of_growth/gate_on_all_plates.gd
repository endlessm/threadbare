# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Triggers one or more targets ONLY when ALL assigned pressure plates are pressed.
## Used for "place all rocks on all plates to open the path" puzzles.

## Array of pressure plates ([PressurePlate]) required to trigger the targets.
@export var plates: Array[Node]
## Target nodes to activate. Uses open()/close() if available (Doors with sound),
## falls back to set_toggled(bool), or toggles collision/visibility for StaticBody2D.
@export var targets: Array[Node]

var _is_open: bool = false


func _ready() -> void:
	for plate in plates:
		if plate and plate.has_signal(&"pressed"):
			plate.pressed.connect(_on_plate_pressed)
	# Initial state without playing sound.
	_is_open = _all_on()
	for target in targets:
		_apply_initial(target, _is_open)


func _on_plate_pressed(_is_on: bool) -> void:
	_check()


func _all_on() -> bool:
	for plate in plates:
		if not is_instance_valid(plate) or not plate.is_on:
			return false
	return true


func _check() -> void:
	_set_open(_all_on())


func _set_open(value: bool) -> void:
	if value == _is_open:
		return
	_is_open = value
	for target in targets:
		if not is_instance_valid(target):
			continue
		if value and target.has_method("open"):
			target.open()
		elif not value and target.has_method("close"):
			target.close()
		elif target.has_method("set_toggled"):
			target.set_toggled(value)
		elif target is StaticBody2D:
			(target as StaticBody2D).set_deferred(&"collision_layer", 0 if value else 16)
			target.visible = not value


func _apply_initial(target: Node, value: bool) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("set_toggled"):
		target.set_toggled(value)
	elif target is StaticBody2D:
		(target as StaticBody2D).set_deferred(&"collision_layer", 0 if value else 16)
		target.visible = not value
