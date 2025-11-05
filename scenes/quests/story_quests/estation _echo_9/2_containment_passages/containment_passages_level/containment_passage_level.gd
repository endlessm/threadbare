# containment_passage_level.gd
extends Node2D

# --- Referencias a nuestros nodos ---
@onready var dialogue_label: Label = $CanvasLayer/Dialogue_Label
@onready var dialogue_timer: Timer = $Dialogue_Timer

# --- Secuencia de Diálogo (Traducida del GDD) ---
var dialogue_sequence: Array[String] = [
	"Minigame 2: The Containment Passages", # Título
	"Narrator: The path to the second core is teeming with movement. But nothing here should be moving.", # Narración
	"AI: Warning: Body heat signatures... multiple.", # Diálogo IA
	"Elara: Body heat... corpses?", # Diálogo Elara
	"" # Limpiar
]
var current_dialogue_index: int = 0

func _ready() -> void:
	# Inicia la secuencia de diálogo
	_show_next_dialogue()

	# --- CONECTAR TODAS LAS SEÑALES ---

	# 1. Conectar la Meta (Ganar)
	$Goal_Area.body_entered.connect(_on_goal_area_body_entered)

	# 2. Conectar el Timer de Diálogo
	$Dialogue_Timer.timeout.connect(_on_dialogue_timer_timeout)

	# 3. Conectar TODOS los enemigos (Perder)
	# Esto busca cada nodo en el grupo "ecos" que creamos
	for eco in get_tree().get_nodes_in_group("ecos"):
		# Conecta la "alarma" (player_detected) de CADA eco a nuestra función de perder
		eco.player_detected.connect(_on_eco_player_detected)

# --- Funciones de Diálogo ---
func _show_next_dialogue() -> void:
	if current_dialogue_index < dialogue_sequence.size():
		dialogue_label.text = dialogue_sequence[current_dialogue_index]
		current_dialogue_index += 1
		dialogue_timer.start(4.0) # 4 segundos por línea
	else:
		dialogue_label.hide() # Oculta el texto al terminar

func _on_dialogue_timer_timeout() -> void:
	_show_next_dialogue() # Muestra la siguiente línea

# --- Funciones de Ganar/Perder ---
func _on_goal_area_body_entered(body: Node2D) -> void:
	# Si el que entró a la meta es el jugador
	if body.is_in_group("player"):
		print("¡GANASTE! OBTUVISTE EL NÚCLEO 2") # Meta del GDD: Obtener el segundo núcleo
		get_tree().reload_current_scene() # Por ahora, reinicia el nivel

func _on_eco_player_detected() -> void:
	# El GDD dice "atacan instantáneamente"
	print("¡TE VIERON! ATAQUE INSTANTÁNEO.") 
	get_tree().reload_current_scene() # Reinicia el nivel
