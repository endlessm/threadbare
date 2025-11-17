extends Node2D

func _on_salida_escena_area_entered(area: Area2D) -> void:
	print("Área de salida detectó un ÁREA.")
	if area.is_in_group("player"):
		print("¡Es el jugador! Cambiando de escena...")
		var error: Error = get_tree().change_scene_to_file("res://scenes/quests/story_quests/la_leyenda_de_quispe/1_fase/Main/Main.tscn")
		if error != OK:
			print("ERROR: No se pudo cargar la escena.")
	else:
		print("Un área entró, pero NO era el jugador.")
