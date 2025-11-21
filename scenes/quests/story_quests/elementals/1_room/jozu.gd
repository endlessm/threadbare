class_name Jozu
extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var speed: float = 250.0
@export var momentum_factor: float = 0.5

# Configuración de Ráfaga
@export var shoot_cooldown: float = 0.15 

# --- VARIABLES DE DASH ---
@export var dash_speed: float = 600.0 
@export var dash_duration: float = 0.4 
@export var dash_cooldown: float = 2.0 

var can_shoot: bool = true
var shoot_cooldown_counter: float = 0.0

# --- Variables de Estado ---
var is_attacking: bool = false
var is_hurting: bool = false 
var is_dead: bool = false 

# --- Variables de Estado Dash ---
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN
# ---------------------------------------

# Contador de secuencia de disparo (1 a 5)
var fire_sequence_index: int = 1 

var last_shoot_direction: Vector2 = Vector2.DOWN 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Referencias a los nodos de disparo ---
@onready var bullet_spawn_raycast: RayCast2D = $BulletSpawnRaycast
@onready var spawn_right: Marker2D = $SpawnPointRight
@onready var spawn_left: Marker2D = $SpawnPointLeft
@onready var spawn_up: Marker2D = $SpawnPointUp
@onready var spawn_down: Marker2D = $SpawnPointDown
# ---------------------------------------------

var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(delta):
	
	# --- 0. GESTIÓN DE TIEMPOS ---
	if not can_shoot:
		shoot_cooldown_counter += delta
		if shoot_cooldown_counter >= shoot_cooldown:
			can_shoot = true
			shoot_cooldown_counter = 0.0
			
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			stop_dash()
	
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true

	# --- 1. ACTIVACIÓN DEL DASH ---
	if Input.is_action_just_pressed("sokoban_skip") and can_dash and not is_hurting and not is_dead and not is_dashing:
		start_dash()

	# --- 2. LÓGICA DE MOVIMIENTO ---
	if is_dashing:
		velocity = dash_direction * dash_speed
		
	elif not is_attacking and not is_hurting and not is_dead:
		var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = move_direction * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# --- 3. LÓGICA DE ANIMACIÓN ---
	if not is_attacking and not is_hurting and not is_dead and not is_dashing:
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
	
	# --- 4. LÓGICA DE DISPARO (SECUENCIAL 1 al 5) ---
	if can_shoot and not is_hurting and current_health_halves > 0 and not is_dashing:
		if Input.is_action_pressed("sokoban_undo"):
			
			is_attacking = true
			
			# ### LÓGICA DE SECUENCIA EXTENDIDA ###
			match fire_sequence_index:
				1: 
					# 1 Bala: Centro
					shoot(facing_direction)
				2:
					# 2 Balas: Poco abiertas
					shoot(facing_direction.rotated(deg_to_rad(-5)))
					shoot(facing_direction.rotated(deg_to_rad(5)))
				3:
					# 3 Balas: Centro + Abiertas
					shoot(facing_direction)
					shoot(facing_direction.rotated(deg_to_rad(-15)))
					shoot(facing_direction.rotated(deg_to_rad(15)))
				4:
					# 4 Balas: 2 Internas + 2 Externas
					shoot(facing_direction.rotated(deg_to_rad(-7)))
					shoot(facing_direction.rotated(deg_to_rad(7)))
					shoot(facing_direction.rotated(deg_to_rad(-20)))
					shoot(facing_direction.rotated(deg_to_rad(20)))
				5:
					# 5 Balas: ABANICO TOTAL (Centro + Medias + Extremas)
					shoot(facing_direction) # Centro
					shoot(facing_direction.rotated(deg_to_rad(-12))) # Medias
					shoot(facing_direction.rotated(deg_to_rad(12)))
					shoot(facing_direction.rotated(deg_to_rad(-25))) # Externas
					shoot(facing_direction.rotated(deg_to_rad(25)))
			
			# Aumentamos contador
			fire_sequence_index += 1
			
			# Reiniciamos después de 5
			if fire_sequence_index > 5:
				fire_sequence_index = 1 
			
			# Animación
			if facing_direction == Vector2.UP:
				start_attack_visual("attack_back", true)
			elif facing_direction == Vector2.DOWN:
				start_attack_visual("attack_front", true)
			elif facing_direction == Vector2.LEFT:
				start_attack_visual("attack_side", true)
			elif facing_direction == Vector2.RIGHT:
				start_attack_visual("attack_side", false)
			
			can_shoot = false
			
	# --- 5. PARPADEO ---
	update_blinking_effect()

# --- FUNCIONES DE DASH ---

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = facing_direction
	
	animated_sprite.modulate = Color(0.5, 0.5, 1, 0.8)
	fire_burst()

func stop_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 1)

func fire_burst():
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	directions.append_array([
		Vector2(1,1).normalized(),
		Vector2(-1,1).normalized(),
		Vector2(1,-1).normalized(),
		Vector2(-1,-1).normalized()
	])
	for dir in directions:
		shoot(dir)

# -----------------------------------------

func start_attack_visual(anim_name: String, flip_needed: bool):
	animated_sprite.play(anim_name)
	animated_sprite.frame = 0 
	
	if anim_name == "attack_side":
		animated_sprite.flip_h = flip_needed

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
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func take_damage(damage_amount_halves: int = 1):
	if is_invulnerable or is_hurting or is_dead or is_dashing: 
		return
	
	if current_health_halves <= 0: return

	current_health_halves -= damage_amount_halves
	current_health_halves = max(0, current_health_halves)
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
	health_changed.emit(current_health_halves)

func add_heart_container():
	max_health_halves += 2
	heal(2)

func die():
	if is_dead: return
	is_dead = true
	is_attacking = false
	is_hurting = false
	died.emit()
	set_physics_process(false)
	animated_sprite.play("die")

func _on_invulnerability_timer_timeout():
	is_invulnerable = false

func update_blinking_effect():
	if is_invulnerable and not is_dashing:
		animated_sprite.modulate.a = abs(sin(Time.get_ticks_msec() * 0.02))
	elif not is_dashing:
		animated_sprite.modulate.a = 1.0

# --- FUNCIÓN DE DISPARO ---
func shoot(shoot_direction: Vector2):
	if not bullet_scene: return

	var bullet = bullet_scene.instantiate()
	bullet.direction = shoot_direction
	
	var target_marker: Marker2D
	if shoot_direction.x > 0: target_marker = spawn_right
	elif shoot_direction.x < 0: target_marker = spawn_left
	elif shoot_direction.y < 0: target_marker = spawn_up
	else: target_marker = spawn_down

	var target_local_pos = bullet_spawn_raycast.to_local(target_marker.global_position)
	bullet_spawn_raycast.target_position = target_local_pos
	bullet_spawn_raycast.force_raycast_update()
	
	var spawn_pos: Vector2
	if bullet_spawn_raycast.is_colliding():
		spawn_pos = bullet_spawn_raycast.get_collision_point()
	else:
		spawn_pos = target_marker.global_position
		
	bullet.global_position = spawn_pos
	bullet.rotation = shoot_direction.angle()
	get_tree().current_scene.add_child(bullet)
	
	var bullet_base_velocity = shoot_direction * bullet.speed
	var final_velocity
	
	if is_dashing:
		final_velocity = bullet_base_velocity
	else:
		final_velocity = bullet_base_velocity + (velocity * momentum_factor)
		
	bullet.linear_velocity = final_velocity


func _on_animation_finished():
	var anim_name = animated_sprite.animation
	
	if anim_name == "attack_front" or anim_name == "attack_back" or anim_name == "attack_side":
		is_attacking = false
		
	if anim_name == "hurt":
		is_hurting = false

	if anim_name == "die":
		hide()
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy_projectile"):
		call_deferred("take_damage", 1)
		body.queue_free()
