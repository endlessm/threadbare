# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D


func randomize() -> void:
	var rain_type := randf()
	if rain_type < 0.25:
		# 25% chances of having a drizzle.
		gpu_particles_2d.amount_ratio = randf_range(0, 0.1)
	elif rain_type >= 0.75:
		# 25% chances of having a steady rain.
		gpu_particles_2d.amount_ratio = randf_range(0.8, 1)
	else:
		# 50% chances of having something in between.
		gpu_particles_2d.amount_ratio = randf_range(0.1, 0.8)


func fade_in(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = true
	visible = true


func fade_out(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = false
	await gpu_particles_2d.finished
	visible = false
