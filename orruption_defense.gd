extends Node2D

@export var zones: Array[CorruptionZone]

var current_zone: CorruptionZone


func _ready() -> void:
	select_random_zone()


func _process(delta: float) -> void:
	if current_zone:
		current_zone.increase_corruption(delta * 5.0)
		
		print(
			current_zone.name,
			" -> ",
			round(current_zone.corruption)
		)


func select_random_zone() -> void:
	if zones.is_empty():
		return

	current_zone = zones.pick_random()

	print("Corrupting: ", current_zone.name)
