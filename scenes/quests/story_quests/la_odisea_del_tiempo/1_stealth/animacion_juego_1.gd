# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var animacion: AnimationPlayer
@export var player: Player
@export var sprite_2:AnimatedSprite2D
@export var area_deteccion:Area2D
func animacion_1()->void:
	player.take_control(self)
	animacion.play("cutscenes")
	await get_tree().create_timer(2).timeout
	animacion.pause()
	player.return_control(self)

func activar_cinematica_2()->void:
	sprite_2.visible=true
	area_deteccion.monitoring = true
