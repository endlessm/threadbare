extends Sprite2D

func CuandoEntraJugador(body: Node2D) -> void:
	if body.is_in_group("player"):
		var nodoRaiz = $"../.."
		nodoRaiz.llaves += 1
		nodoRaiz.ActualizarLlaves()
		queue_free()
		if nodoRaiz.llaves == 3:
			$"../../CamaraPuerta".enabled = true
			$"../../Player/Camera2D".enabled = false
			$"../../TimerPuerta".start()
