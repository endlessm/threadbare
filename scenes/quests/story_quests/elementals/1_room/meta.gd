extends Node2D

## ¡Aquí puedes elegir la escena!
@export_file("*.tscn") var escena_siguiente: String

## (Opcional) Si quieres que aparezca en un punto específico
@export var spawn_point_path: String = ""

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Verificamos si el 'body' que entró está en el grupo "player".
	if body.is_in_group("player"):
		
		if escena_siguiente == "":
			print("ERROR: No asignaste escena siguiente.")
			return

		# --- CORRECCIÓN ---
		# En lugar de cortar de golpe, usamos SceneSwitcher para hacer FADE (Fundido)
		SceneSwitcher.change_to_file_with_transition(
			escena_siguiente,
			spawn_point_path,
			Transition.Effect.FADE, # Efecto de entrada
			Transition.Effect.FADE  # Efecto de salida
		)
