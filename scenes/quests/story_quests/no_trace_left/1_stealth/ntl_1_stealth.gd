extends Node2D

@onready var interact_area = $Sprite2D/InteractArea
@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
		
func _ready() -> void:
	call_deferred("_intro_player")
	if interact_area.has_signal("interaction_ended"):
		interact_area.interaction_ended.connect(finish)

func _intro_player() -> void:
	var player = $Player
	if player:
		if player.get_node_or_null("%PlayerRepel"):
			player._toggle_player_behavior(player.player_repel, false)
			
		if player.get_node_or_null("%PlayerHook"):
			player._toggle_player_behavior(player.player_hook, false)

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
