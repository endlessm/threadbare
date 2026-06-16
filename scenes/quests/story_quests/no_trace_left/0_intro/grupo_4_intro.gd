extends Node2D

@onready var interact_area = $NtlPapers/InteractArea
@onready var area_phone = $NtlPhone/InteractArea
@onready var sprite_2d = $NtlPapers

@export_file("*.tscn") var next_scene: String
@export var spawn_point_path: String
@export var revealed: bool = true:
	set(new_value):
		revealed = new_value
		_update_based_on_revealed()
		
func _ready() -> void:
	call_deferred("_intro_player")
	if area_phone.has_signal("interaction_ended"):
		area_phone.interaction_ended.connect(reveal)
		
	if interact_area.has_signal("interaction_ended"):
		interact_area.interaction_ended.connect(finish)
		call_deferred("_intro_player")
	
func _update_based_on_revealed() -> void:
	if interact_area:
		interact_area.disabled = not revealed
	if sprite_2d:
		sprite_2d.visible = revealed
	call_deferred("_intro_player")

func _intro_player() -> void:
	var player = $Player
	if player:
		if player.get_node_or_null("%PlayerRepel"):
			player._toggle_player_behavior(player.player_repel, false)
			
		if player.get_node_or_null("%PlayerHook"):
			player._toggle_player_behavior(player.player_hook, false)
	
func reveal() -> void:
	revealed = true
	area_phone.disabled = true
	call_deferred("_intro_player")
	
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
	
