# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends "res://scenes/game_elements/characters/player/components/player.gd"

var posicion_inicial: Vector2

func _ready() -> void:
	super._ready()
	add_to_group("player")
	posicion_inicial = global_position

func _process(delta: float) -> void:
	super._process(delta)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("obstacle"):
			defeat()
			return
