extends Node2D

func _ready():
	print("toco musica")
	MusicManager.play_next()
	await get_tree().process_frame  # Espera a que la escena cargue completamente
	var players = get_tree().get_nodes_in_group("player")
	var player = null
	if players.size() > 0:
		player = players[0]
		if GameStateLaberinto.player_position != Vector2.ZERO:
			player.global_position = GameStateLaberinto.player_position
		player.keys_collected = GameStateLaberinto.llaves
		player.update_keys_ui()
		player.set_cofres_abiertos(GameStateLaberinto.abiertos)
