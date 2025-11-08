# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Sprite2D





func CuandoEntraJugador(body: Node2D) -> void:
	if body.is_in_group("player"):

	
		
		# ELIMINAR INMEDIATAMENTE
		queue_free()
		
		if nodoRaiz.llaves == 3:
			$"../../CamaraPuerta".enabled = true
			$"../../Player/Camera2D".enabled = false
			$"../../CamaraPuerta/InteractInput".visible = true
			$"../../TimerPuerta".start()
