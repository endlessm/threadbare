extends Area2D

@export var recurso_dialogo: DialogueResource
var esta_hablando: bool = false # Este es nuestro interruptor

func _on_body_entered(_body: Node2D) -> void:
	if _body.name == "Player" and not esta_hablando:
		esta_hablando = true
		
		# 1. Cargamos tu escena personalizada
		var balloon_scene = load("res://scenes/quests/story_quests/perdidos_en_el_desie/2_combat/balloon_guardian.tscn") # REEMPLAZA ESTA RUTA
		var balloon = balloon_scene.instantiate()
		
		# 2. La añadimos a la escena actual
		get_tree().current_scene.add_child(balloon)
		
		# 3. Iniciamos el diálogo en tu globo personalizado
		# Nota: La mayoría de globos de diálogo tienen una función llamada .start()
		balloon.start(recurso_dialogo, "inicio_guardian")
		
		# 4. Esperamos a que se cierre
		await balloon.tree_exited
		esta_hablando = false
		
		# --- ACTIVAMOS EL DISPARO Y DEVOLVEMOS EL CONTROL ---
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			player.puede_disparar = true
			player.mode = Player.Mode.USER_CONTROLLED # <--- ESTO ES LO QUE FALTA
			print("¡Habilidad activada y control devuelto!")
