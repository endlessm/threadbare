extends Node2D

func _ready() -> void:
	call_deferred("_intro_player")

func _intro_player() -> void:
	var player = $OnTheGround/Player
	if player:
		if player.get_node_or_null("%PlayerRepel"):
			player._toggle_player_behavior(player.player_repel, false)
			
		if player.get_node_or_null("%PlayerHook"):
			player._toggle_player_behavior(player.player_hook, false)
