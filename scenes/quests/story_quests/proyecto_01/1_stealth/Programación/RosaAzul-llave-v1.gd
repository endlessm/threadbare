# RosaAzul-llave-v1.gd
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var nivel = get_tree().current_scene
		if nivel.has_method("ActualizarLlaves"):
			nivel.ActualizarLlaves()  # <- nada de nivel.llaves += 1
		queue_free()
