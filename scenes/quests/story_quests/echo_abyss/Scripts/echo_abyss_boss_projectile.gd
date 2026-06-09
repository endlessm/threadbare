# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EchoAbyssBossProjectile
extends Projectile

func got_repelled(repel_direction: Vector2) -> void:
	can_hit_enemy = true
	can_hit_player = false
	super.got_repelled(repel_direction)
