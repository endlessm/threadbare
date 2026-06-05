extends Node2D

@export var zones: Array[CorruptionZone]

var current_zone: CorruptionZone
var player_was_inside := {}


func _ready() -> void:

	for zone in zones:
		player_was_inside[zone] = false

	select_random_zone()


func _process(delta: float) -> void:

	if current_zone:
		current_zone.increase_corruption(delta * 5.0)

	for zone in zones:

		if zone.player_inside:
			zone.decrease_corruption(delta * 10.0)

		var was_inside = player_was_inside[zone]

		if zone.player_inside and not was_inside:

			print("Player discovered ", zone.name)

			if zone == current_zone:
				print("Shadow escaped!")

				select_random_zone()

		player_was_inside[zone] = zone.player_inside


func select_random_zone() -> void:
	if zones.is_empty():
		return

	var available_zones := zones.filter(
		func(zone):
			return zone != current_zone
	)

	if available_zones.is_empty():
		return

	current_zone = available_zones.pick_random()

	print("Corrupting: ", current_zone.name)
