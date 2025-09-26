extends CharacterBody2D


@export var speed: float = 100
@export var attack_cooldown: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $Area2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var scream_player: AudioStreamPlayer2D = $ScreamPlayer

var player: Node2D = null
var can_attack: bool = true
var has_screamed: bool = false  # <- control de grito por detección

func _ready() -> void:
	$CollisionShape2D.disabled = false  
	vision_area.body_entered.connect(_on_body_entered)
	vision_area.body_exited.connect(_on_body_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_timer.timeout.connect(_on_attack_timeout)

	sprite.play("idle")

func _physics_process(_delta: float) -> void:
	if player:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		# 🔍 Debug: ¿está colisionando?
		var collision = get_last_slide_collision()
		if collision != null:
			print("¡Kaenamanto chocó con:", collision.get_collider())
		sprite.flip_h = direction.x < 0
		if sprite.animation != "default":
			sprite.play("default")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite.animation != "idle":
			sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body

		if not has_screamed:
			has_screamed = true
			print("¡Jugador detectado! Reproduciendo grito.")
			if scream_player.playing:
				scream_player.stop()
			scream_player.play()

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		has_screamed = false  # Permite volver a gritar si sale y entra

func _on_attack_area_entered(body: Node2D) -> void:
	if body.name == "Player" and can_attack:
		can_attack = false
		sprite.play("attack")

		await get_tree().create_timer(0.5).timeout
		get_tree().reload_current_scene()

func _on_attack_timeout() -> void:
	can_attack = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	pass  # No se usa en este diseño
