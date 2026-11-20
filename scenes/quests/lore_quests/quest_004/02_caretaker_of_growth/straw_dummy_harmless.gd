# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Harmless straw dummy (decorative).
## Shakes when the player touches or approaches it, and stops when the player leaves.

## Shake intensity on contact (px).
@export var tremble_amplitude: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea


func _ready() -> void:
	# Duplicate material to prevent all dummies from shaking simultaneously.
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	_set_tremble(0.0)
	touch_area.body_entered.connect(_on_body_entered)
	touch_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_set_tremble(tremble_amplitude)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_set_tremble(0.0)


func _set_tremble(amount: float) -> void:
	if sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter(&"amplitude", amount)
