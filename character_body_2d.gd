extends CharacterBody2D

@onready var recarga_timer = $tiempo_bala_peon
@onready var puntero_peon = $puntero_peon

@onready var anim = $AnimatedSprite2D
@export var vida_max = 10
@export var vida = 10
@export var bala_escena = preload("res://scenes/quests/story_quests/spacerage/pruebas/bala_enemiga_peon.tscn")
@export var canIshoot = false
@export var isTarget = false
@export var shooting_point = 10
@onready var recibir_daño_sonido = $"recibir_daño_peon"
@onready var detector = $"detector_de_daño"
@onready var disparo_timer = $Timer_disparo

@export var velocidad = 100
@export var rango = 150.0
@export var disparos_maximos = 5

var centro = Vector2.ZERO
var direccion = Vector2.ZERO
var disparos_actuales = 0


func _ready():
	detector.connect("body_entered", Callable(self, "_on_body_entered")) 
	centro = global_position
	_actualizar_direccion()
	

	recarga_timer.timeout.connect(_disparar)
	recarga_timer.start()
	if !isTarget:
		anim.play("idle")
	else:
		anim.play("target_idle")
	

func _disparar():

	var jugador = get_tree().current_scene.get_node_or_null("Player")
	if jugador == null:
		print("Jugador no encontrado")
		return
	if jugador.global_position.x >= shooting_point && !isTarget:
		canIshoot = true

	if canIshoot == true:
		disparo_timer.timeout.connect(_disparar)
		recarga_timer.timeout.connect(_terminar_recarga)
		disparo_timer.start()

		if disparos_actuales >= disparos_maximos:
			recarga_timer.start(2.0)
			disparo_timer.stop()
			return


		anim.play("alerted")
		var bala = bala_escena.instantiate()
		bala.global_position = puntero_peon.global_position
		bala.direccion = (jugador.global_position - bala.global_position).normalized()
		get_tree().current_scene.add_child(bala)
		disparos_actuales += 1

func _terminar_recarga():
	disparos_actuales = 0
	_actualizar_direccion()
	disparo_timer.start()

func _actualizar_direccion():
	direccion = Vector2.RIGHT.rotated(randf() * TAU)

func _physics_process(delta):
	if not canIshoot:
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(centro) >= rango or is_on_wall():
		velocity = Vector2.ZERO
	else:
		velocity = direccion * velocidad
	move_and_slide()


func recibir_daño(cantidad):
	if !isTarget:
		recibir_daño_sonido.play()

	
	vida -= cantidad
	vida = clamp(vida, 0, vida_max)
	print("Enemigo recibió ", cantidad, " de daño. Vida restante: ", vida)
	$vida_1.value = vida
	$vida_1.max_value = vida_max

	if vida <= 0:
		recarga_timer.stop()
		if !isTarget:
			# animacion de muerte del enemigos
			#anim.play("die")
			print("entro 1")
		else:
			# animacion de muerte del target
			print("entro 2")
			anim.play("target_destroy")
			await anim.animation_finished
		
		queue_free()
		
