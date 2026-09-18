extends Node

const TOWNIE_NAMES: Array[String] = [
	"Felicity Fastneedle",
	"Cedric Chiffon",
	"Avery Threadwell",
	"Rowan Woolstitch",
	# ... tus demás nombres
]

var townie_name: String


func _ready() -> void:
	_assign_random_name()

	print("Primera vez: ", get_townie_name())
	print("Segunda vez: ", get_townie_name())
	print("Tercera vez: ", get_townie_name())


func _assign_random_name() -> void:
	if TOWNIE_NAMES.is_empty():
		push_warning("RandomName: No Townie names available.")
		return

	townie_name = TOWNIE_NAMES.pick_random()
	print("Townie generated: ", townie_name)


func get_townie_name() -> String:
	return townie_name
