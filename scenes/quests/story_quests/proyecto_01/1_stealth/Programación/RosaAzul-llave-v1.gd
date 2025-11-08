extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Busca el script de control principal (nivel o manager)
		var nivel = get_tree().current_scene
		if nivel.has_method("ActualizarLlaves"):
			nivel.llaves += 1
			nivel.ActualizarLlaves()
		queue_free()
