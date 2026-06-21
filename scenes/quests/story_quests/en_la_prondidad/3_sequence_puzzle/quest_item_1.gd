extends Area2D

const RECURSO_DIALOGO = preload("res://scenes/quests/story_quests/en_la_prondidad/3_sequence_puzzle/componentes/en_la_prondidad_sequence_puzzle.dialogue")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		set_deferred("monitoring", false)
		visible = false

		body.take_control(self)

		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO

		var sprite_animado: AnimatedSprite2D = body.get_node_or_null("PlayerSprite")

		if sprite_animado:
			sprite_animado.play("idle")

		if DialogueManager:
			DialogueManager.show_dialogue_balloon(RECURSO_DIALOGO, "objeto_1_recogido", [body])
			await DialogueManager.dialogue_ended

		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO

		if sprite_animado:
			sprite_animado.play("idle")

		body.return_control(self)

		var nodos_puerta = get_tree().get_nodes_in_group("puerta_principal")
		if nodos_puerta.size() > 0:
			var la_puerta = nodos_puerta[0]
			if la_puerta.has_method("registrar_objeto"):
				la_puerta.registrar_objeto()

		queue_free()
