# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends GPUParticles2D

@onready var player: Player = owner


func _on_input_walk_behavior_running_changed(is_running: bool) -> void:
	emitting = is_running
	if emitting:
		process_material.direction = Vector3(player.velocity.x, player.velocity.y, 0.0)
