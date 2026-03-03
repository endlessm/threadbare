# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CanvasLayer

@export_tool_button("Random Rain") var randomize_button: Callable = randomize

@export var _seed: int:
	set = _set_seed

var _random_number_generator := RandomNumberGenerator.new()

@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D


func _set_seed(new_seed: int) -> void:
	_seed = new_seed
	_random_number_generator.seed = _seed
	var rain_type := _random_number_generator.randf()
	prints("RAIN", rain_type)
	if not gpu_particles_2d:
		return
	if rain_type < 0.25:
		# 25% chances of having a drizzle.
		gpu_particles_2d.amount_ratio = _random_number_generator.randf_range(0, 0.1)
	elif rain_type >= 0.75:
		# 25% chances of having a steady rain.
		gpu_particles_2d.amount_ratio = _random_number_generator.randf_range(0.8, 1)
	else:
		# 50% chances of having something in between.
		gpu_particles_2d.amount_ratio = _random_number_generator.randf_range(0.1, 0.8)


func randomize() -> void:
	_set_seed(randi())


func fade_in(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = true
	visible = true


func fade_out(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = false
	await gpu_particles_2d.finished
	visible = false
