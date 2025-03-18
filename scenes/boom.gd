extends Node2D
@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	var color: Color = Globals.INK_COLORS[ink_color_name]
	modulate = color
	gpu_particles_2d.emitting = true
	await gpu_particles_2d.finished
	queue_free()
