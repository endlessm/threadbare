extends CharacterBody2D

@onready var tiempo_peon_bala = $tiempo_bala_peon
@onready var puntero_peon = $puntero_peon

@onready var anim = $AnimatedSprite2D
@export var vida_max = 10
@export var vida = 10
@export var bala_escena = preload("res://scenes/quests/story_quests/spacerage/pruebas/bala_enemiga_peon.tscn")
@export var canIshoot = false
@export var isTarget = false

func _ready():
	tiempo_peon_bala.timeout.connect(_disparar)
	tiempo_peon_bala.start()
	if !isTarget:
		anim.play("idle")
	else:
		anim.play("target_idle")
	

func _disparar():
	
	var jugador = get_tree().current_scene.get_node_or_null("Player")
	if jugador == null:
		print("Jugador no encontrado")
		return
	if jugador.global_position >= Vector2(2256.683, 368.451):
		canIshoot = true

	if canIshoot == true:
		anim.play("alerted")
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
		
