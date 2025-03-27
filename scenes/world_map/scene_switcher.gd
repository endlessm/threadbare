extends Node


func change_scene_to(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if get_tree().change_scene_to_file(scene_path) == OK and spawn_point != ^"":
		GameState.current_spawn_point = spawn_point
