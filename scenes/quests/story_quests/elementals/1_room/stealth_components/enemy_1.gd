extends CharacterBody2D
class_name Enemy

# --- Estados del Enemigo ---
enum State { IDLE, CHASING, ATTACKING, COOLDOWN, DEFEATED }

# --- Variables de Comportamiento ---
@export var speed: float = 200.0
@export var attack_range: float = 50.0  
@export var attack_damage: int = 1
@export var attack_cooldown: float = 2.0 

# --- ¡NUEVAS VARIABLES DE VIDA! ---
@export var max_health: int = 3 # ¡Muere a los 3 golpes!
var current_health: int
# ---------------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea 

var player: CharacterBody2D = null
var is_attacking: bool = false 

var current_state: State = State.IDLE

var cooldown_counter: float = 0.0

func _ready():
	# --- ¡NUEVO! ---
	# Establece la vida al máximo al empezar
	current_health = max_health
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	add_to_group("enemy")

func _physics_process(delta):
	
	if current_state == State.DEFEATED:
		velocity = Vector2.ZERO 
		move_and_slide()
		return 

	if current_state == State.COOLDOWN:
		cooldown_counter += delta
		if cooldown_counter >= attack_cooldown:
			cooldown_counter = 0.0
			current_state = State.IDLE
			
	var new_state = get_new_state()
	
	if new_state != current_state:
		current_state = new_state

	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity = Vector2.ZERO
			
		State.CHASING:
			animated_sprite.play("walk") 
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * speed
			
			if direction.x > 0.1:
				animated_sprite.flip_h = false 
			elif direction.x < -0.1:
				animated_sprite.flip_h = true 
			
		State.ATTACKING:
			velocity = Vector2.ZERO 
			
			if not is_attacking:
				is_attacking = true
				animated_sprite.play("attack")
				_do_damage()
			
		State.COOLDOWN:
			velocity = Vector2.ZERO
			animated_sprite.play("idle") 
		
		State.DEFEATED:
			velocity = Vector2.ZERO
			
	move_and_slide()

func get_new_state() -> State:
	if current_state == State.DEFEATED or is_attacking or current_state == State.COOLDOWN:
		return current_state
		
	if not is_instance_valid(player):
		return State.IDLE
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range:
		return State.ATTACKING
	else:
		return State.CHASING

func _do_damage():
	if is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range * 1.2: 
			player.take_damage(attack_damage)
			print("Enemigo: ¡GOLPE!")

func _on_animation_finished():
	if animated_sprite.animation == "attack":
		current_state = State.COOLDOWN
		is_attacking = false
	
	if animated_sprite.animation == "defeated":
		queue_free() 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body 
		print("Enemigo: ¡Te veo!")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player = null 
		print("Enemigo: ¿A dónde fue?")

# --- ¡NUEVA FUNCIÓN DE PARPADEO! ---
func flash_red():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0), 0.0)
	tween.tween_interval(0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.0)

# --- ¡NUEVA FUNCIÓN DE RECIBIR DAÑO! ---
func take_damage(amount: int):
	if current_state == State.DEFEATED:
		return

	current_health -= amount
	print("Vida del enemigo: ", current_health)

	if current_health <= 0:
		die()
	else:
		flash_red()

# --- ¡Función de Morir! ---
func die():
	if current_state == State.DEFEATED:
		return

	current_state = State.DEFEATED
	
	$CollisionShape2D.disabled = true
	detection_area.monitoring = false
	
	animated_sprite.play("defeated")
	
# --- ¡ESTA ES LA FUNCIÓN CORREGIDA! ---
# (Se eliminó el 'pass' extra y se corrigió la indentación)
func _on_hit_box_body_entered(body: Node2D) -> void:
	# Comprobamos si el 'body' que entró está en el grupo "bullet"
	if body.is_in_group("bullet"):
	
		# 1. Llama a la función de morir (de forma segura)
		call_deferred("take_damage",1)
	
		# 2. Destruye la bala que nos golpeó
		body.queue_free()
