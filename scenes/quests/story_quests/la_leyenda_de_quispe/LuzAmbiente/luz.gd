extends PointLight2D

@export var min_energy: float = 0.8
@export var max_energy: float = 1.2
@export var min_scale: float = 0.95
@export var max_scale: float = 1.05
@export var speed: float = 5.0
var time: float = 0.0

func _ready() -> void:
	time = randf() * 100.0

func _process(delta: float) -> void:
	time += delta * speed
	var wave: float = (sin(time) + 1.0) / 2.0
	energy = lerp(min_energy, max_energy, wave)
	texture_scale = lerp(min_scale, max_scale, wave)
