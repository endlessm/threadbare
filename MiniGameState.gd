extends Node

var collected_names: Array[String] = []
var current_scene: String = ""

func register(item_name: String, scene: String) -> void:
	if scene != current_scene:
		collected_names.clear()
		current_scene = scene
	if item_name not in collected_names:
		collected_names.append(item_name)

func is_collected(item_name: String, scene: String) -> bool:
	if scene != current_scene:
		return false
	return item_name in collected_names

func reset() -> void:
	collected_names.clear()
	current_scene = ""
