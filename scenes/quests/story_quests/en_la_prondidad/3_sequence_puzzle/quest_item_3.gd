extends Area2D

# Cargamos el recurso de tus diálogos
const RECURSO_DIALOGO = preload("res://scenes/quests/story_quests/en_la_prondidad/3_sequence_puzzle/componentes/en_la_prondidad_sequence_puzzle.dialogue")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false
	set_deferred("monitoring", false)

# Función para que el puzzle haga aparecer este objeto
func reveal() -> void:
	visible = true
	set_deferred("monitoring", true)
	print("¡Puzzle de baldosas resuelto! Aparece el Objeto 3.")

func _on_body_entered(body: Node) -> void:
	if body is Player:
		set_deferred("monitoring", false)
		visible = false
		body.take_control(self)
		
		var sprite_animado: AnimatedSprite2D = null
		if body.has_node("PlayerSprite"):
			sprite_animado = body.get_node("PlayerSprite") as AnimatedSprite2D
		elif body.has_node("%PlayerSprite"):
			sprite_animado = body.get_node("%PlayerSprite") as AnimatedSprite2D
			
		if sprite_animado and sprite_animado.has_method("play"):
			sprite_animado.play(&"idle")
		
		# AQUÍ ESTÁ EL CAMBIO: Llama a "objeto_3_recogido"
		if DialogueManager:
			DialogueManager.show_dialogue_balloon(RECURSO_DIALOGO, "objeto_3_recogido", [body])
			await DialogueManager.dialogue_ended
		
		body.return_control(self)
		
		# 5. SUMAR PUNTO A LA PUERTA Y ELIMINAR EL OBJETO
		var nodos_puerta = get_tree().get_nodes_in_group("puerta_principal")
		if nodos_puerta.size() > 0:
			var la_puerta = nodos_puerta[0]
			if la_puerta.has_method("registrar_objeto"):
				la_puerta.registrar_objeto()
		
		queue_free()
