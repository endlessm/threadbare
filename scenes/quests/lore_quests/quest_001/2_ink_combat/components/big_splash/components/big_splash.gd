# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D


func _ready() -> void:
	gpu_particles_2d.emitting = true
	await gpu_particles_2d.finished
	queue_free()
