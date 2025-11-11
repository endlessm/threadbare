extends Area2D

@export var new_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		change_scene()
	pass 
func change_scene():
	get_tree().change_scene_to_file(new_scene_path)
