# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CanvasLayer

@export_tool_button("Random Rain") var randomize_button: Callable = randomize_effect

@export var _seed: int:
	set = _set_seed

## The probability distribution for the amount of rain. The y-axis is the amount
## of rain for a given (randomly-chosen) point on the x-axis.
@export var rain_distribution: Curve

var _random_number_generator := RandomNumberGenerator.new()

@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D


func _set_seed(new_seed: int) -> void:
	_seed = new_seed
	_random_number_generator.seed = _seed
	if not gpu_particles_2d:
		return
	var x := _random_number_generator.randf()
	var rain_amount := rain_distribution.sample(x)
	gpu_particles_2d.amount_ratio = rain_amount


func randomize_effect() -> void:
	_set_seed(randi())


func fade_in(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = true
	visible = true


func fade_out(_duration: float = 1) -> void:
	gpu_particles_2d.emitting = false
	await gpu_particles_2d.finished
	visible = false
