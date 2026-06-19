extends Node2D

const SPEED_NUBE = 55

var juego_activo = false
var puertas_habilitadas = false
var boton_acertijo_presionado = false

@onready var dialogue_balloon = $Dialogue
@onready var nube = $NubeNegra
@onready var player = $Player
@onready var musica_fondo = $MusicaFondo

# Los 4 zombies de la sala, todos usan el mismo script reutilizable (zombie.gd)
@onready var zombie1 = $Zombie
@onready var zombie2 = $Zombie2
@onready var zombie3 = $Zombie3
@onready var zombie4 = $Zombie4

@onready var puerta_fija = $Puerta
@onready var puerta_fija2 = $Puerta2

func _ready():
	randomize()
	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)
	puerta_fija.global_position = Vector2(2573, 730)
	puerta_fija2.global_position = Vector2(2573, 115)

	if musica_fondo:
		musica_fondo.stop()

	# Conectar los 4 zombies
	for zombie in [zombie1, zombie2, zombie3, zombie4]:
		if zombie:
			zombie.player_detected.connect(_on_player_detected)
			# No se mueven mientras corre el diálogo / el juego no ha empezado
			zombie.set_activo(false)

	# Las puertas empiezan bloqueadas hasta confirmar si el acertijo ya fue resuelto
	_actualizar_estado_puertas_inicial()

	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

func _on_player_detected(player_node: Node2D) -> void:
	_game_over()

func _iniciar_dialogo():
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/room2.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		_iniciar_juego()

func _on_dialogue_finished():
	if get_tree():
		await get_tree().create_timer(0.1).timeout
	_iniciar_juego()

func _iniciar_juego():
	juego_activo = true
	if musica_fondo and not musica_fondo.playing:
		musica_fondo.play()

	# Los 4 zombies empiezan a moverse junto con el juego
	for zombie in [zombie1, zombie2, zombie3, zombie4]:
		if zombie:
			zombie.set_activo(true)

func _on_letra_iluminada(nodo: Node2D) -> void:
	if not juego_activo:
		return
	if nodo.has_method("revelar_desde_player"):
		nodo.revelar_desde_player()

func _on_letra_oscurecida(nodo: Node2D) -> void:
	if not juego_activo:
		return
	if nodo.has_method("oscurecer_desde_player"):
		nodo.oscurecer_desde_player()

func _on_button_pressed():
	boton_acertijo_presionado = true
	habilitar_puertas()
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Puzzle8.tscn")

## Habilita ambas puertas (se llama cuando se presiona el botón ACERTIJO).
func habilitar_puertas() -> void:
	puertas_habilitadas = true
	if puerta_fija:
		puerta_fija.puede_abrirse = true
	if puerta_fija2:
		puerta_fija2.puede_abrirse = true

## Llamado en _ready: deja el mensaje de bloqueo correcto en ambas puertas.
## Bloqueadas mientras el botón ACERTIJO no haya sido presionado.
func _actualizar_estado_puertas_inicial() -> void:
	for puerta in [puerta_fija, puerta_fija2]:
		if puerta:
			puerta.mensaje_bloqueo = "No se puede abrir hasta encontrar el botón ACERTIJO"
			puerta.puede_abrirse = boton_acertijo_presionado

func _game_over():
	juego_activo = false
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.tscn")

func _input(_event: InputEvent):
	pass
