# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Muñeco de paja INOFENSIVO (decorativo). No patrulla ni te detecta: solo
## TIEMBLA cuando el jugador lo toca / se acerca, y se queda quieto al alejarse.
## Para la sala 1 del invernadero (Sable advierte de ellos, pero no hacen daño).

## Cuánto tiembla al tocarlo (px). El temblor está apagado mientras nadie lo toca.
@export var tremble_amplitude: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea


func _ready() -> void:
	# Material propio por muñeco (si no, temblarían todos a la vez).
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
