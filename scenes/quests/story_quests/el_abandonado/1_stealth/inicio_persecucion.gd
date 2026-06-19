extends Area2D

@onready var lich = $"../Enemy"
@onready var jugador = $"../Player"

var activado := false

func _on_body_entered(body):

	if activado:
		return

	if body.name == "Player":

		activado = true

		jugador.velocity = Vector2.ZERO

		jugador.mode = Player.Mode.SYSTEM_CONTROLLED

		lich.iniciar_entrada()
