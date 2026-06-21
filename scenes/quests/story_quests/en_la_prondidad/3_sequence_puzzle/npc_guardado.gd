extends Area2D

const RUTA_GUARDADO: String = "user://save_game_quest_profundidad.dat"
const RECURSO_DIALOGO = preload("res://scenes/quests/story_quests/en_la_prondidad/3_sequence_puzzle/componentes/en_la_prondidad_sequence_puzzle.dialogue")
@export var animacion: AnimatedSprite2D
static var forzar_carga_al_iniciar: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if forzar_carga_al_iniciar:
		forzar_carga_al_iniciar = false
		_restaurar_partida()
		
	animacion.play("idle")

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_control(self)
		
		var sprite_animado: AnimatedSprite2D = null
		if body.has_node("PlayerSprite"):
			sprite_animado = body.get_node("PlayerSprite") as AnimatedSprite2D
		elif body.has_node("%PlayerSprite"):
			sprite_animado = body.get_node("%PlayerSprite") as AnimatedSprite2D
			
		if sprite_animado and sprite_animado.has_method("play"):
			sprite_animado.play(&"idle")
			
		var total_objetos_actuales: int = 0
		# TIPADO ESTÁTICO: Le decimos que es un Array de Nodos
		var nodos_puerta: Array[Node] = get_tree().get_nodes_in_group("puerta_principal")
		if nodos_puerta.size() > 0:
			total_objetos_actuales = nodos_puerta[0].objetos_recogidos
		
		# SOLUCIÓN OBJETOS: Guardamos una lista de nombres (Strings)
		var items_vivos: Array[String] = []
		for item in get_tree().get_nodes_in_group("recolectables_quest"):
			items_vivos.append(item.name)
		
		# TIPADO ESTÁTICO: Textos y Diccionarios
		var ruta_escena_actual: String = get_tree().current_scene.scene_file_path
		var datos_partida: Dictionary = {
			"escena_actual": ruta_escena_actual,
			"objetos_recogidos": total_objetos_actuales,
			"items_vivos": items_vivos
		}
		
		# TIPADO ESTÁTICO: Objeto de tipo Archivo (FileAccess)
		var archivo: FileAccess = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
		if archivo:
			var json_string: String = JSON.stringify(datos_partida)
			archivo.store_string(json_string)
			archivo.close()
			print("¡Partida guardada! Objetos en poder: ", total_objetos_actuales)
		
		if DialogueManager:
			DialogueManager.show_dialogue_balloon(RECURSO_DIALOGO, "partida_guardada", [body])
			await DialogueManager.dialogue_ended
			
		body.return_control(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		if FileAccess.file_exists(RUTA_GUARDADO):
			# Activamos la bandera estática y reiniciamos el mapa
			forzar_carga_al_iniciar = true
			
			var archivo: FileAccess = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
			if archivo:
				var json: JSON = JSON.new()
				if json.parse(archivo.get_as_text()) == OK:
					var datos: Dictionary = json.get_data() as Dictionary
					var escena_a_cargar: String = datos.get("escena_actual", "")
					
					if escena_a_cargar != "" and SceneSwitcher:
						SceneSwitcher.change_to_file_with_transition(escena_a_cargar, "", Transition.Effect.FADE, Transition.Effect.FADE)

# --- FUNCIÓN NUEVA DE RESTAURACIÓN BLINDADA ---
func _restaurar_partida() -> void:
	# 1. Esperamos un frame de Godot para que todos los árboles y muros aparezcan
	await get_tree().process_frame
	
	var archivo: FileAccess = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo:
		var json: JSON = JSON.new()
		if json.parse(archivo.get_as_text()) == OK:
			var datos: Dictionary = json.get_data() as Dictionary
			
			# SOLUCIÓN ERROR 2.0: Convertimos el dato a Entero (int)
			var objetos_guardados: int = int(datos.get("objetos_recogidos", 0))
			var items_vivos: Array = datos.get("items_vivos", [])
			
			# SOLUCIÓN OBJETOS DOBLES: Destruimos los objetos que no estaban en nuestra lista guardada
			for item in get_tree().get_nodes_in_group("recolectables_quest"):
				if not item.name in items_vivos:
					item.queue_free()
					
			# SOLUCIÓN ERROR "CAJA RETIRADA": Esperamos a que las físicas locas del inicio se calmen
			await get_tree().create_timer(0.2).timeout
			
			# Forzamos la puerta a tener el valor correcto sin interrupciones
			var nodos_puerta: Array[Node] = get_tree().get_nodes_in_group("puerta_principal")
			if nodos_puerta.size() > 0:
				nodos_puerta[0].objetos_recogidos = objetos_guardados
				print("Carga finalizada con éxito. La puerta tiene: ", objetos_guardados)
