extends Area2D

@export var advertencia_dialogue: DialogueResource

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

		if advertencia_dialogue:
			DialogueManager.show_dialogue_balloon(advertencia_dialogue)
			await DialogueManager.dialogue_ended

		lich.iniciar_entrada()
