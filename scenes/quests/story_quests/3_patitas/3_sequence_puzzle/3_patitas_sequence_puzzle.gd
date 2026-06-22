extends Node2D

var cristales_recolectados = 0
const TOTAL_CRISTALES = 5

# Variables para el efecto de vibración (Shake)
var debe_vibrar = false
var intensidad_vibracion = 4.0 
var posicion_original_cohete = Vector2.ZERO

# Configuración de la luz
const ESCALA_INICIAL_X = 0.08
const ESCALA_INICIAL_Y = 0.08
const INCREMENTO_ESCALA = 0.05
const MAX_ESCALA = 1.3

@onready var linterna_gato = $OnTheGround/Player/PointLight2D2
@onready var cohete = $CoheteDespegue

func _ready() -> void:
	if linterna_gato:
		linterna_gato.scale = Vector2(ESCALA_INICIAL_X, ESCALA_INICIAL_Y)
		linterna_gato.energy = 1.2
		
	if cohete:
		posicion_original_cohete = cohete.position

	for nodo in find_children("CristalLunar*", "Node", true, false):
		var area_real: Area2D = null
		if nodo is Area2D: area_real = nodo
		elif nodo is Sprite2D and nodo.get_parent() is Area2D: area_real = nodo.get_parent() as Area2D
		
		if area_real:
			if not area_real.body_entered.is_connected(_on_cristal_recolectado):
				area_real.body_entered.connect(_on_cristal_recolectado.bind(area_real))
				

	await get_tree().process_frame # Espera un milisegundo a que la pantalla cargue
	var recurso_dialogo = load("res://scenes/quests/story_quests/3_patitas/3_sequence_puzzle/3_patitas_sequence_puzzle.dialogue")
	if recurso_dialogo:
		_desplegar_interfaz_dialogo(recurso_dialogo, "start")
	# =========================================================================

func _process(delta: float) -> void:
	# Si la victoria se activó, el cohete vibrará cada fotograma
	if debe_vibrar and cohete:
		var desfase_x = randf_range(-intensidad_vibracion, intensidad_vibracion)
		var desfase_y = randf_range(-intensidad_vibracion, intensidad_vibracion)
		cohete.position = posicion_original_cohete + Vector2(desfase_x, desfase_y)

func _on_cristal_recolectado(body: Node2D, cristal_nodo: Node2D) -> void:
	if body.name == "Player" or body is CharacterBody2D:
		var numero_cristal = 1
		if cristal_nodo.name.to_lower() != "cristallunar":
			numero_cristal = cristal_nodo.name.to_int()
		
		if numero_cristal != (cristales_recolectados + 1):
			_mostrar_aviso_orden()
			return
			
		cristales_recolectados += 1
		cristal_nodo.queue_free()
		
		if linterna_gato:
			var nueva_escala = ESCALA_INICIAL_X + (INCREMENTO_ESCALA * cristales_recolectados)
			linterna_gato.scale = Vector2(min(nueva_escala, MAX_ESCALA), min(nueva_escala, MAX_ESCALA))
		
		if cristales_recolectados >= TOTAL_CRISTALES:
			_ejecutar_dialogo_final()

func _mostrar_aviso_orden() -> void:
	var recurso_dialogo = load("res://scenes/quests/story_quests/3_patitas/3_sequence_puzzle/3_patitas_sequence_puzzle.dialogue")
	if recurso_dialogo:
		_desplegar_interfaz_dialogo(recurso_dialogo, "advertencia")

func _ejecutar_dialogo_final() -> void:
	if cohete:
		cohete.visible = true
		debe_vibrar = true 
		
	var recurso_dialogo = load("res://scenes/quests/story_quests/3_patitas/3_sequence_puzzle/3_patitas_sequence_puzzle.dialogue")
	if recurso_dialogo:
		_desplegar_interfaz_dialogo(recurso_dialogo, "well_done")
	
	await get_tree().create_timer(5.0).timeout
	debe_vibrar = false
	_cambiar_a_escena_espacial()

func _desplegar_interfaz_dialogo(recurso, titulo_seccion: String) -> void:
	if DialogueManager.has_method("show_dialogue_balloon"):
		DialogueManager.show_dialogue_balloon(recurso, titulo_seccion)
	else:
		DialogueManager.show_example_dialogue_balloon(recurso, titulo_seccion)

func _cambiar_a_escena_espacial() -> void:
	var ruta_outro = "res://scenes/quests/story_quests/3_patitas/4_outro/3_patitas_outro.tscn"
	get_tree().change_scene_to_file(ruta_outro)
