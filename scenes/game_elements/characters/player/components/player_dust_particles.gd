# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends GPUParticles2D

@onready var player: Player = owner


func _process(_delta: float) -> void:
	if not player:
		return
	if player.is_running() and not player.velocity.is_zero_approx():
		emitting = true
		process_material.direction = Vector3(player.velocity.x, player.velocity.y, 0.0)
	else:
		emitting = false
