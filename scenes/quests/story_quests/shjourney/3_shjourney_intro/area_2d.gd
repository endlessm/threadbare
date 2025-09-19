extends Area2D

func _on_Area2D_body_entered(body: Node) -> void:
	if body.name == "Player":
		print("¡Jugador detectado!")
		$"../Cinematic_siguiente".start_cinematic()
