extends Node2D

@onready var interact_area = $Sprite2D/InteractArea
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
		
func _ready() -> void:
	if interact_area.has_signal("interaction_ended"):
		interact_area.interaction_ended.connect(finish)

func finish() -> void:
	if next_scene:
		(
			SceneSwitcher
			. change_to_file_with_transition(
				next_scene,
				spawn_point_path,
				Transition.Effect.FADE,
				Transition.Effect.FADE,
			)
		)
