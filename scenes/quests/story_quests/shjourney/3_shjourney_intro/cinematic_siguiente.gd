extends Node2D
class_name Cinematic_siguiente

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String

var _has_switched := false

func start_cinematic() -> void:
	if _has_switched:
		return
	_has_switched = true

	if next_scene:
		SceneSwitcher.change_to_file_with_transition(
			next_scene,
			spawn_point_path,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
