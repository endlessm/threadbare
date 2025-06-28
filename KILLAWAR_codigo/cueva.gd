extends Area2D
@export var next_escene_path: String
func _on_body_entered(body: Node2D) -> void:
	print("+1 hhola") # Replace with function body.
	
	if body.name == "Chaska":
		print("soy chaska")
		change_escene()

func change_escene():
	get_tree().change_scene_to_file(next_escene_path)
