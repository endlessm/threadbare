extends Area2D

@export var next_escene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "chaska":
		change_escene()

func change_escene():
	get_tree().change_scene_to_file(next_escene_path)
