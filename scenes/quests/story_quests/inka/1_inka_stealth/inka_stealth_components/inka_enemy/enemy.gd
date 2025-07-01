extends CharacterBody2D

@export var move_vertical: bool = true  # Si es falso, se mueve horizontalmente
@export var speed: float = 30.0
@export var chase_speed: float = 100.0

var direction := Vector2.ZERO
var player_detected := false
var player: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

func _ready():
	direction = Vector2.DOWN if move_vertical else Vector2.RIGHT

func _physics_process(delta):
	if player_detected and player:
		# Perseguir al jugador
		var to_player = (player.global_position - global_position).normalized()
		velocity = to_player * chase_speed
	else:
		# Movimiento patrullando
		velocity = direction * speed
		sprite.play("Run")

	move_and_slide()
	if not player_detected:
		if get_last_slide_collision() != null:
			direction = -direction

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = true
		player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = false
		player = null

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		sprite.play("Attack")
		if body.has_method("take_damage"):
			body.take_damage(1)
		

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		sprite.play("Idle")
