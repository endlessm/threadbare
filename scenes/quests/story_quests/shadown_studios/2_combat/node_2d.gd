extends Node2D

@export var rotation_speed: float = 200.0

func _process(delta):
	rotation_degrees += rotation_speed * delta
