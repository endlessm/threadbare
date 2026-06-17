extends Node2D

const SPEED_NUBE = 55
const SPEED_ZOMBIE = 40
const ZOMBIE_MIN = Vector2(0, 0)
const ZOMBIE_MAX = Vector2(1200, 700)

var juego_activo = false
var zombie_dir = Vector2.RIGHT
var zombie_cambio_dir_timer = 0.0

@onready var dialogue_balloon = $Dialogue
@onready var nube = $NubeNegra
@onready var player = $Player
@onready var musica_fondo = $MusicaFondo
@onready var bestia = $Zombie
@onready var guardia1 = $Guard
@onready var guardia2 = $Guard2
@onready var guardia3 = $Guard3

func _ready():
	randomize()
	player.letra_iluminada.connect(_on_letra_iluminada)
	player.letra_oscurecida.connect(_on_letra_oscurecida)

	if guardia1:
		guardia1.player_detected.connect(_on_player_detected)
	if guardia2:
		guardia2.player_detected.connect(_on_player_detected)
	if guardia3:
		guardia3.player_detected.connect(_on_player_detected)

	zombie_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	if musica_fondo:
		musica_fondo.stop()
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

func _process(delta):
	if not juego_activo:
		return
	_mover_zombie(delta)

func _mover_zombie(delta: float) -> void:
	if not bestia:
		return
	var distancia = bestia.position.distance_to(player.position)

	if distancia < 200.0:
		var dir = (player.position - bestia.position).normalized()
		bestia.position += dir * SPEED_ZOMBIE * delta
	else:
		zombie_cambio_dir_timer -= delta
		if zombie_cambio_dir_timer <= 0:
			zombie_cambio_dir_timer = randf_range(1.5, 3.5)
			zombie_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

		bestia.position += zombie_dir * SPEED_ZOMBIE * delta

		if bestia.position.x < ZOMBIE_MIN.x or bestia.position.x > ZOMBIE_MAX.x:
			zombie_dir.x = -zombie_dir.x
			bestia.position.x = clamp(bestia.position.x, ZOMBIE_MIN.x, ZOMBIE_MAX.x)
		if bestia.position.y < ZOMBIE_MIN.y or bestia.position.y > ZOMBIE_MAX.y:
			zombie_dir.y = -zombie_dir.y
			bestia.position.y = clamp(bestia.position.y, ZOMBIE_MIN.y, ZOMBIE_MAX.y)

	if distancia < 80:
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
