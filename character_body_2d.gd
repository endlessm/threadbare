extends CharacterBody2D

@onready var tiempo_peon_bala = $tiempo_bala_peon
@onready var puntero_peon = $puntero_peon


@export var vida_max = 10
@export var vida = 10
@export var bala_escena = preload("res://scenes/quests/story_quests/spacerage/pruebas/bala_enemiga_peon.tscn")
@export var canIshoot = 0

func _ready():
	tiempo_peon_bala.timeout.connect(_disparar)
	tiempo_peon_bala.start()

func _disparar():
	
	var jugador = get_tree().current_scene.get_node_or_null("Player")
	if jugador == null:
		print("Jugador no encontrado")
		return
	if jugador.global_position >= Vector2(2256.683, 368.451):
		canIshoot = 1

	if canIshoot == 1:
		var bala = bala_escena.instantiate()
		bala.global_position = puntero_peon.global_position
		bala.direccion = (jugador.global_position - bala.global_position).normalized()
		get_tree().current_scene.add_child(bala)

func recibir_daño(cantidad):
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	print("Enemigo recibió ", cantidad, " de daño. Vida restante: ", vida)
	$vida_1.value = vida
	$vida_1.max_value = vida_max

	if vida <= 0:
		tiempo_peon_bala.stop()
		queue_free()
