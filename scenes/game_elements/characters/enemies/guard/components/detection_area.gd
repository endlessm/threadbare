# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D

const LOOK_AT_TURN_SPEED: float = 10.0

@onready var character: CharacterBody2D = owner


func _physics_process(delta: float) -> void:
	if character.velocity.is_zero_approx():
		return

	var offset := 0.0

	if character.is_in_group("vertical_guard"):
		offset = 90.0

	var target_angle = character.velocity.angle() + deg_to_rad(offset)
	rotation = rotate_toward(rotation, target_angle, delta * LOOK_AT_TURN_SPEED)
