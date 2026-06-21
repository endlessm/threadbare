extends Area2D

# Esta variable guardará cuántos objetos de quest ha recogido el jugador
var objetos_recogidos: int = 0

# Ruta de la siguiente escena a la que teletransportará la puerta
@export_file("*.tscn") var siguiente_escena: String = "uid://bsrxki3uvqybt"

# Cargamos el recurso de tus diálogos traumáticos
const RECURSO_DIALOGO = preload("res://scenes/quests/story_quests/en_la_prondidad/3_sequence_puzzle/componentes/en_la_prondidad_sequence_puzzle.dialogue")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Limpiamos el código antiguo del objeto_2 que ya no se usa, evitando errores en consola.

func _on_body_entered(body: Node) -> void:
	# Verificamos si el cuerpo que entró es el jugador usando su clase nativa
	if body is Player:
		# ADAPTACIÓN: Ahora basta con tener 3 objetos recogidos para avanzar
		if objetos_recogidos >= 3:
			print("¡Puerta abierta! Cambiando de escena...")
			if siguiente_escena:
				SceneSwitcher.change_to_file_with_transition(
					siguiente_escena, "", Transition.Effect.FADE, Transition.Effect.FADE
				)
		else:
			print("La puerta está cerrada. Llevas: ", objetos_recogidos)
			
			# 1. CONGELAR AL JUGADOR: Evita que siga corriendo contra la puerta
			body.take_control(self)
			
			# 2. MOSTRAR DIÁLOGO DE BLOQUEO
			if DialogueManager:
				# Llamamos al bloque específico 'puerta_cerrada' pasándole al jugador
				DialogueManager.show_dialogue_balloon(RECURSO_DIALOGO, "puerta_cerrada", [body])
				# Esperamos a que el jugador termine de leer y cierre el diálogo
				await DialogueManager.dialogue_ended
				
			# 3. DEVOLVER EL CONTROL AL JUGADOR
			body.return_control(self)
   
# Esta función la llamaremos desde los scripts de los objetos cuando sean recogidos
func registrar_objeto() -> void:
	objetos_recogidos += 1
	print("Objeto registrado en la puerta. Total actual: ", objetos_recogidos)
