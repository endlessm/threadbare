class_name Jozu
extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var speed: float = 250.0
@export var momentum_factor: float = 0.5
@export var shoot_cooldown: float = 2.0

var can_shoot: bool = true
var cooldown_counter: float = 0.0

# --- Variables de Estado ---
var is_attacking: bool = false
var is_hurting: bool = false 
var is_dead: bool = false 

# ** NUEVA VARIABLE **
# Sirve para recordar hacia dónde disparar cuando termine la animación
var last_shoot_direction: Vector2 = Vector2.DOWN 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- (Referencias a los nodos de disparo) ---
@onready var bullet_spawn_raycast: RayCast2D = $BulletSpawnRaycast
@onready var spawn_right: Marker2D = $SpawnPointRight
@onready var spawn_left: Marker2D = $SpawnPointLeft
@onready var spawn_up: Marker2D = $SpawnPointUp
@onready var spawn_down: Marker2D = $SpawnPointDown
# ---------------------------------------------

var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(delta):
	
	# --- 1. LÓGICA DE COOLDOWN ---
	if not can_shoot:
		cooldown_counter += delta
		if cooldown_counter >= shoot_cooldown:
			can_shoot = true
			cooldown_counter = 0.0

	# --- 2. LÓGICA DE MOVIMIENTO (WASD) ---
	var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if not is_attacking and not is_hurting and not is_dead:
		velocity = move_direction * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# --- 3. LÓGICA DE ANIMACIÓN (MOVIMIENTO) ---
	if not is_attacking and not is_hurting and current_health_halves > 0:
		if velocity.length() > 0:
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = false 

			if abs(velocity.x) > 0:
				facing_direction = Vector2(sign(velocity.x), 0)
			elif abs(velocity.y) > 0:
				facing_direction = Vector2(0, sign(velocity.y))

			if velocity.x < 0:
				animated_sprite.flip_h = true 
			elif velocity.x > 0:
				animated_sprite.flip_h = false 
		else:
			animated_sprite.play("idle")
	
	# --- 4. LÓGICA DE DISPARO (FLECHAS) ---
	if can_shoot and not is_attacking and not is_hurting and current_health_halves > 0:
		if Input.is_action_pressed("shoot_up"):
			start_attack("attack_back", Vector2.UP, false)
			
		elif Input.is_action_pressed("shoot_down"):
			start_attack("attack_front", Vector2.DOWN, false)

		elif Input.is_action_pressed("shoot_left"):
			start_attack("attack_side", Vector2.LEFT, true)

		elif Input.is_action_pressed("shoot_right"):
			start_attack("attack_side", Vector2.RIGHT, false)
			
	# --- 5. LÓGICA DE PARPADEO ---
	update_blinking_effect()

# --- FUNCIÓN AUXILIAR PARA INICIAR ATAQUE ---
# Esto limpia el código de arriba y prepara el disparo diferido
func start_attack(anim_name: String, dir: Vector2, flip: bool):
	is_attacking = true
	can_shoot = false
	last_shoot_direction = dir # Guardamos la dirección para usarla al final de la animacion
	animated_sprite.play(anim_name)
	animated_sprite.flip_h = flip
	# NOTA: Aquí NO llamamos a shoot(). Esperamos a la señal.


# --- CÓDIGO DE VIDA ---
@export var max_health_halves: int = 6
var current_health_halves: int
signal health_changed(new_health)
signal died
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
var is_invulnerable: bool = false

func _ready():
	current_health_halves = max_health_halves
	health_changed.emit(current_health_halves)
	invulnerability_timer.timeout.connect(_on_invulnerability_timer_timeout)
	
	# Conectamos la señal de fin de animación
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func take_damage(damage_amount_halves: int = 1):
	if is_invulnerable or is_hurting or is_dead: return
	if current_health_halves <= 0: return

	current_health_halves -= damage_amount_halves
	current_health_halves = max(0, current_health_halves)
	print("Vida actual: ", current_health_halves)
	health_changed.emit(current_health_halves)
	
	if current_health_halves == 0:
		die()
	else:
		is_invulnerable = true
		invulnerability_timer.start()
		
		is_attacking = false
		is_hurting = true
		animated_sprite.play("hurt")

func heal(heal_amount_halves: int = 1):
	current_health_halves += heal_amount_halves
	current_health_halves = min(current_health_halves, max_health_halves)
	print("Vida actual: ", current_health_halves)
	health_changed.emit(current_health_halves)

func add_heart_container():
	max_health_halves += 2
	heal(2)

func die():
	if is_dead: return
	is_dead = true
	is_attacking = false
	is_hurting = false
	print("¡El jugador ha muerto!")
	died.emit()
	set_physics_process(false)
	animated_sprite.play("die")

func _on_invulnerability_timer_timeout():
	is_invulnerable = false

func update_blinking_effect():
	if is_invulnerable:
		animated_sprite.modulate.a = abs(sin(Time.get_ticks_msec() * 0.02))
	else:
		animated_sprite.modulate.a = 1.0

# --- FUNCIÓN DE DISPARO (LÓGICA DE BALA) ---
func shoot(shoot_direction: Vector2):
	if not bullet_scene:
		print("ERROR: No se asignó la 'Bullet Scene' en el Inspector.")
		return

	var bullet = bullet_scene.instantiate()
	bullet.direction = shoot_direction
	
	var spawn_pos: Vector2
	var target_marker: Marker2D
	if shoot_direction == Vector2.RIGHT:
		target_marker = spawn_right
	elif shoot_direction == Vector2.LEFT:
		target_marker = spawn_left
	elif shoot_direction == Vector2.UP:
		target_marker = spawn_up
	else:
		target_marker = spawn_down

	var target_local_pos = bullet_spawn_raycast.to_local(target_marker.global_position)
	bullet_spawn_raycast.target_position = target_local_pos
	bullet_spawn_raycast.force_raycast_update()
	
	if bullet_spawn_raycast.is_colliding():
		spawn_pos = bullet_spawn_raycast.get_collision_point()
	else:
		spawn_pos = target_marker.global_position
		
	bullet.global_position = spawn_pos
	
	if shoot_direction == Vector2.LEFT:
		bullet.rotation_degrees = 180
	elif shoot_direction == Vector2.UP:
		bullet.rotation_degrees = -90
	elif shoot_direction == Vector2.DOWN:
		bullet.rotation_degrees = 90
	
	get_tree().current_scene.add_child(bullet)
	
	var bullet_base_velocity = shoot_direction * bullet.speed
	var final_velocity = bullet_base_velocity + (velocity * momentum_factor)
	bullet.linear_velocity = final_velocity


# --- FUNCIÓN DE FIN DE ANIMACIÓN (AQUÍ DISPARAMOS) ---
func _on_animation_finished():
	var anim_name = animated_sprite.animation
	
	# Si terminó una animación de ataque, DISPARAMOS AHORA
	if anim_name == "attack_front" or anim_name == "attack_back" or anim_name == "attack_side":
		shoot(last_shoot_direction) # <--- AQUÍ SALE LA BALA AL FINAL
		is_attacking = false
		
	if anim_name == "hurt":
		is_hurting = false

	if anim_name == "die":
		hide()
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy_projectile"):
		call_deferred("take_damage",1)
		body.queue_free()
