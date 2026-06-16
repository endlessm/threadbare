extends Node2D

const SPEED_NUBE = 55

var juego_activo = false

@onready var dialogue_balloon = $Dialogue
@onready var nube = $NubeNegra
@onready var player = $Player
@onready var musica_fondo = $MusicaFondo

func _ready():
	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)

	if musica_fondo:
		musica_fondo.stop()

	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

func _iniciar_dialogo():
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/room2.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		_iniciar_juego()

func _on_dialogue_finished():
	await get_tree().process_frame
	_iniciar_juego()

func _iniciar_juego():
	juego_activo = true
	if musica_fondo and not musica_fondo.playing:
		musica_fondo.play()

func _process(delta):
	if not juego_activo:
		return
	var dir = (player.position - nube.position).normalized()
	nube.position += dir * SPEED_NUBE * delta
	if nube.position.distance_to(player.position) < 80:
		_game_over()

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
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Puzzle8.tscn")

func _game_over():
	juego_activo = false
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.tscn")

func _input(_event: InputEvent):
	pass
