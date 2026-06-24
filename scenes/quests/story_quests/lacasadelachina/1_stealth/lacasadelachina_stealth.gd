extends Node2D

@onready var guardian    = get_node("EnemyGuards/Guard1-GoingBackAndForth")
@onready var guardian2   = get_node("EnemyGuards/Guard2-GoingBackAndForth2")
@onready var guardian3   = get_node("EnemyGuards/Guard3-GoingBackAndForth3")
@onready var memory_game = get_node("ScreenOverlay/Memorygame")

var guardian_bloqueado := true
var llave_recogida = false
var timer_llave: Timer

func _ready() -> void:
	memory_game.minijuego_completado.connect(_on_minijuego_completado)
	memory_game.ronda_completada_signal.connect(_on_ronda_completada)

	var zone1 = get_node_or_null("EnemyGuards/Guard1-GoingBackAndForth/zonewar")
	var zone2 = get_node_or_null("EnemyGuards/Guard2-GoingBackAndForth2/zonewar")
	var zone3 = get_node_or_null("EnemyGuards/Guard3-GoingBackAndForth3/zonewar")
	if zone1:
		zone1.body_entered.connect(_on_zonewar_body_entered)
	if zone2:
		zone2.body_entered.connect(_on_zonewar_body_entered)
	if zone3:
		zone3.body_entered.connect(_on_zonewar_body_entered)

func _mover_llave():
	pass

func llave_recogida_por_jugador():
	pass

func _on_ronda_completada(ronda: int) -> void:
	# Cuando termina una ronda, chequeamos si el jugador ya está
	# dentro de la zona del siguiente guardia
	var zona = null
	if ronda == 1:
		zona = get_node_or_null("EnemyGuards/Guard2-GoingBackAndForth2/zonewar")
	elif ronda == 2:
		zona = get_node_or_null("EnemyGuards/Guard3-GoingBackAndForth3/zonewar")

	if zona:
		for body in zona.get_overlapping_bodies():
			if body.is_in_group("player"):
				_on_zonewar_body_entered(body)

func _on_zonewar_body_entered(body: Node2D) -> void:
	print("Zona tocada por: ", body.name)
	if guardian_bloqueado and body.is_in_group("player"):
		print("¡Jugador detectado! Iniciando minijuego...")
		var ronda = memory_game.ronda_actual
		if ronda == 0 and is_instance_valid(guardian):
			guardian.set_process(false)
			guardian.set_physics_process(false)
		elif ronda == 1 and is_instance_valid(guardian2):
			guardian2.set_process(false)
			guardian2.set_physics_process(false)
		elif ronda == 2 and is_instance_valid(guardian3):
			var detection = guardian3.get_node_or_null("DetectionArea")
			if detection:
				detection.monitoring = false
			guardian3.set_process(false)
			guardian3.set_physics_process(false)
		memory_game.iniciar()

func _on_minijuego_completado() -> void:
	guardian_bloqueado = false
