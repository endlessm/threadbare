extends CharacterBody2D

@export var move_vertical: bool = true
@export var speed: float = 30.0
@export var chase_speed: float = 100.0
@export var attack_delay: float = 0.5  # Tiempo antes de activar el hit area

var direction := Vector2.ZERO
var player_detected := false
var player: CharacterBody2D = null
var player_in_attack_range: bool = false
var is_attacking: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var hit_area = $HitArea  # Nuevo Hit Area
@onready var hit_area_collision = $HitArea/CollisionShape2D  # Collision del Hit Area

func _ready():
	direction = Vector2.DOWN if move_vertical else Vector2.RIGHT
	hit_area_collision.disabled = true

func _physics_process(delta):
	if player_detected and player:
		var to_player = (player.global_position - global_position).normalized()
		velocity = to_player * chase_speed
		handle_flip(to_player.x)
	else:
		velocity = direction * speed
		sprite.play("Run")
		if not move_vertical:
			handle_flip(direction.x)

	move_and_slide()
	
	if not player_detected and get_last_slide_collision() != null:
		direction = -direction

func handle_flip(player_relative_x: float) -> void:
	# Corrección en la lógica de dirección:
	# - Jugador a la derecha (x > 0) -> flip_h = true (mirar a la derecha)
	# - Jugador a la izquierda (x < 0) -> flip_h = false (mirar a la izquierda)
	var should_face_right = player_relative_x > 0
	
	if sprite.flip_h != should_face_right:
		sprite.flip_h = should_face_right
		
		# Invertir posición de todas las áreas y sus colisiones
		invert_area_position(attack_area)
		invert_area_position(detection_area)
		invert_area_position(hit_area)

func invert_area_position(area: Area2D) -> void:
	# Invertir posición del área principal
	area.position.x = -area.position.x
	
	# Invertir posición de todos los CollisionShape2D hijos
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape_pos = child.position
			shape_pos.x = -shape_pos.x
			child.position = shape_pos

# Nueva función para manejar la secuencia de ataque
func start_attack_sequence() -> void:
	is_attacking = true
	sprite.play("Attack")
	# Esperar el tiempo de delay antes de activar el hit area
	await get_tree().create_timer(attack_delay).timeout
	
	if player_in_attack_range:  # Verificar que el jugador aún está en rango
		# Activar el hit area para causar daño
		hit_area_collision.disabled = false
		
		# Esperar un frame para que se detecte la colisión
		await get_tree().create_timer(0.1).timeout
		
		# Desactivar el hit area después de causar daño
		hit_area_collision.disabled = true
	
	# Esperar a que termine la animación de ataque
	await sprite.animation_finished
	
	is_attacking = false
	
	# Si el jugador sigue en rango, volver a atacar
	if player_in_attack_range:
		start_attack_sequence()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = true
		player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = false
		player = null
		print("Player perdido")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_attack_range = true
		print("Player en rango de ataque")
		
		# Iniciar la secuencia de ataque si no está atacando
		if not is_attacking:
			start_attack_sequence()
		

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_attack_range = false
		# Si el jugador sale del área, detener cualquier ataque en curso
		is_attacking = false
		print("Player fuera de rango de ataque")


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Hit Area golpeó al jugador!")
		if body.has_method("take_damage"):
			body.take_damage(1)
