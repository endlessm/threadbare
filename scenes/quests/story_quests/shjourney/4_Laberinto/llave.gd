# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Sprite2D

var sonido = get_node_or_null("AudioStreamPlayer2D")



func CuandoEntraJugador(body: Node2D) -> void:
	if body.is_in_group("player"):
		# REPRODUCIR SONIDO
		var sonido = get_node_or_null("AudioStreamPlayer2D")
		if sonido:
			sonido.play()
			# Hacer el sonido independiente del nodo padre, esto se hace por que al eliminarse el nodo no se reproduce el sonido.
			get_tree().current_scene.add_child(sonido)
			sonido.reparent(get_tree().current_scene)
		
		var nodoRaiz = $"../.."
		nodoRaiz.llaves += 1
		nodoRaiz.ActualizarLlaves()
		
		# ELIMINAR INMEDIATAMENTE
		queue_free()
		
		if nodoRaiz.llaves == 3:
			$"../../CamaraPuerta".enabled = true
			$"../../Player/Camera2D".enabled = false
			$"../../CamaraPuerta/InteractInput".visible = true
			$"../../TimerPuerta".start()
