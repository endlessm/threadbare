extends Node2D

@export var zones: Array[Node2D]

var current_zone: Node2D


func _ready() -> void:
	select_random_zone()


func select_random_zone() -> void:
	if zones.is_empty():
		print("No zones assigned")
		return

	current_zone = zones.pick_random()

	print("⚠ Corrupting: ", current_zone.name)
