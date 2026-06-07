# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var camara = $"../Camera2D"
@onready var anim := $AnimatedSprite2D

@export var offset_x := 200.0
@export var offset_y := 0.0

func _process(delta):

	if not camara.persecucion_activa:
		visible = false
		return

	visible = true

	var ancho = get_viewport_rect().size.x

	global_position = Vector2(
		camara.global_position.x - (ancho * 0.5) + offset_x,
		camara.global_position.y + offset_y
	)

	if not anim.is_playing():
		anim.play("idle")


func _on_area_2d_body_entered(body):

	if body.name == "Player":
		body.defeat()
