extends Node


func change_to_file(scene_path: String, spawn_point: NodePath = ^"") -> void:
	var scene: PackedScene = load(scene_path)
	if scene:
		change_to_packed(scene, spawn_point)


func change_to_packed(scene: PackedScene, spawn_point: NodePath = ^"") -> void:
	if get_tree().change_scene_to_packed(scene) == OK and spawn_point != ^"":
		GameState.current_spawn_point = spawn_point
