extends Node2D


## ¡Aquí puedes elegir la escena!
## Arrastra tu archivo .tscn aquí desde el Inspector.
@export_file("*.tscn") var escena_siguiente: String





func _on_area_2d_body_entered(body: Node2D) -> void:
	# Verificamos si el 'body' que entró está en el grupo "player".
	# ¡Asegúrate de que tu jugador esté en este grupo!
	if body.is_in_group("player"):
		
		# Revisamos si hemos asignado una escena en el Inspector.
		if not escena_siguiente:
			print("ERROR (PortalEscena): No se ha asignado una 'escena_siguiente' en el Inspector.")
			return

		# Si todo está bien, cambiamos a la escena.
		get_tree().change_scene_to_file(escena_siguiente)
	pass # Replace with function body.
