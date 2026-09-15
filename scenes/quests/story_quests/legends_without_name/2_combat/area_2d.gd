# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Area2D


# Called when the node enters the scene tree for the first time.
func _on_body_entered(body: Node2D) -> void:
	  # Replace with function Sbody.
	if body is Player:
		reiniciar_nivel(body)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func reiniciar_nivel(body: Node2D) -> void:
	#reinicia la escena completa
	var caidaChara = body.get_node_or_null("PlayerSprite") as AnimatedSprite2D

	# desactivar los hijos del nodo pq molestaban al cambiar a idle, nomas se queda el playersprite
	for hijo in body.get_children():
		if hijo.name != "PlayerSprite":
			hijo.process_mode = Node.PROCESS_MODE_DISABLED
	
	#se hace mas chiquito y desaparece
	var tween= create_tween()
	tween.tween_property(body, "scale", Vector2.ZERO, 2.0)

	caidaChara.play("defeated")

	await get_tree().create_timer(2.1).timeout
	get_tree().call_deferred("reload_current_scene")
