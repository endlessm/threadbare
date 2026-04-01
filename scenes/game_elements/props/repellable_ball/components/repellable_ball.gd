# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RigidBody2D


func got_repelled(direction: Vector2) -> void:
	var hit_vector: Vector2 = direction * 300.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 10.0 * sign(direction.x)
	apply_impulse(hit_vector)
