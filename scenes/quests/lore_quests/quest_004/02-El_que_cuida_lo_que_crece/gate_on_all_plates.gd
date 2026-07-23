# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Abre uno o varios objetivos SOLO cuando TODAS las placas tienen una roca encima.
## Para el puzzle "pon las 3 rocas en las 3 placas para abrir la puerta".
## Cuélgalo en la escena y asígnale las placas y los objetivos.

## Las placas ([PressurePlate]) que hay que pisar todas con una roca.
@export var plates: Array[Node]
## Objetivos a abrir cuando estén las 3: si tienen open()/close() se usan (Door, con
## su sonido); si no, set_toggled(bool); si son StaticBody2D se ocultan (portón/escalera).
@export var targets: Array[Node]

var _is_open: bool = false


func _ready() -> void:
	for plate in plates:
		if plate and plate.has_signal(&"pressed"):
			plate.pressed.connect(_on_plate_pressed)
	# Estado inicial sin sonido.
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
