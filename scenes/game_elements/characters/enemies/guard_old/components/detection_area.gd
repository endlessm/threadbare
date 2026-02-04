# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

const LOOK_AT_TURN_SPEED: float = 10.0

@onready var character: CharacterBody2D = owner


func _physics_process(delta: float) -> void:
	if character.velocity.is_zero_approx():
		return

	var target_angle: float = character.velocity.angle()
	rotation = rotate_toward(rotation, target_angle, delta * LOOK_AT_TURN_SPEED)
