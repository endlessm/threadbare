class_name CorruptionZone
extends Node2D

@export_range(0.0, 100.0)
var corruption: float = 0.0


func increase_corruption(amount: float) -> void:
	corruption = min(corruption + amount, 100.0)


func decrease_corruption(amount: float) -> void:
	corruption = max(corruption - amount, 0.0)
