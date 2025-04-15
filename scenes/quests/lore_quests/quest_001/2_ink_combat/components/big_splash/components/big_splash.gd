# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name BigSplash
extends Node2D
@export var ink_color_name: Projectile.InkColorNames = Projectile.InkColorNames.CYAN

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D


func _ready() -> void:
	var color: Color = Projectile.INK_COLORS[ink_color_name]
	modulate = color
	gpu_particles_2d.emitting = true
	await gpu_particles_2d.finished
	queue_free()
