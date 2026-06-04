extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal boss_defeated

@export_group("Activation")
@export var activation_delay: float = 10.0

@export_group("Movement")
@export var speed: float = 180.0
@export var stop_distance: float = 10.0
@export var min_wait_time: float = 0.4
@export var max_wait_time: float = 1.0
@export var arena_top_left: Vector2 = Vector2(80, 80)
@export var arena_bottom_right: Vector2 = Vector2(1180, 650)

@export_group("Attack")
@export var espectro_scene: PackedScene
@export var min_attack_time: float = 0.8
@export var max_attack_time: float = 1.4
@export var attack_shoot_frame: int = 2

@export_group("Burst Attack")
@export var burst_count: int = 3
@export var burst_delay: float = 0.10
@export var burst_spread_degrees: float = 18.0

@export_group("Health")
@export var max_health: int = 300

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var wander_timer: Timer = get_node_or_null("WanderTimer")
@onready var attack_timer: Timer = get_node_or_null("AttackTimer")
@onready var projectile_spawn: Marker2D = get_node_or_null("ProjectileSpawn")

var current_health: int
var target_position: Vector2
var moving: bool = false
var attacking: bool = false
var has_shot_this_attack: bool = false
var boss_active: bool = false
var player: Node2D = null


func _ready() -> void:
	randomize()

	current_health = max_health
	health_changed.emit(current_health, max_health)

	player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("ERROR: El Player no está en el grupo 'player'.")

	if sprite == null:
		push_error("ERROR: Falta AnimatedSprite2D dentro de Alma del padre.")
		return

	if wander_timer == null:
		push_error("ERROR: Falta WanderTimer dentro de Alma del padre.")
		return

	if attack_timer == null:
		push_error("ERROR: Falta AttackTimer dentro de Alma del padre.")
		return

	if projectile_spawn == null:
		push_error("ERROR: Falta ProjectileSpawn dentro de Alma del padre.")
		return

	if not wander_timer.timeout.is_connected(_on_wander_timer_timeout):
		wander_timer.timeout.connect(_on_wander_timer_timeout)

	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	if not sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		sprite.frame_changed.connect(_on_sprite_frame_changed)

	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)

	boss_active = false
	moving = false
	attacking = false
	velocity = Vector2.ZERO

	_play_idle_animation()

	await get_tree().create_timer(activation_delay).timeout
	start_boss_fight()


func _physics_process(delta: float) -> void:
	if not boss_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if moving:
		_move_to_target()
	else:
		velocity = Vector2.ZERO
		move_and_slide()


func start_boss_fight() -> void:
	if current_health <= 0:
		return

	boss_active = true
	attacking = false
	moving = false
	has_shot_this_attack = false

	print("El alma del padre se activó")

	_choose_new_target()
	_start_attack_timer()


func stop_boss_fight() -> void:
	boss_active = false
	attacking = false
	moving = false
	has_shot_this_attack = false
	velocity = Vector2.ZERO

	if wander_timer != null:
		wander_timer.stop()

	if attack_timer != null:
		attack_timer.stop()

	_play_idle_animation()


func _choose_new_target() -> void:
	if not boss_active:
		return

	if attacking:
		return

	var random_x := randf_range(arena_top_left.x, arena_bottom_right.x)
	var random_y := randf_range(arena_top_left.y, arena_bottom_right.y)

	target_position = Vector2(random_x, random_y)
	moving = true

	_play_idle_animation()


func _move_to_target() -> void:
	var direction := target_position - global_position

	if direction.length() <= stop_distance:
		velocity = Vector2.ZERO
		moving = false
		_play_idle_animation()
		_start_wait()
		move_and_slide()
		return

	velocity = direction.normalized() * speed

	if sprite != null and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	move_and_slide()


func _start_wait() -> void:
	if not boss_active:
		return

	var wait_time := randf_range(min_wait_time, max_wait_time)
	wander_timer.start(wait_time)


func _on_wander_timer_timeout() -> void:
	if not boss_active:
		return

	_choose_new_target()


func _start_attack_timer() -> void:
	if not boss_active:
		return

	var wait_time := randf_range(min_attack_time, max_attack_time)
	attack_timer.start(wait_time)


func _on_attack_timer_timeout() -> void:
	if not boss_active:
		return

	_start_attack()


func _start_attack() -> void:
	if not boss_active:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player == null:
		_start_attack_timer()
		return

	attacking = true
	moving = false
	has_shot_this_attack = false
	velocity = Vector2.ZERO

	sprite.flip_h = player.global_position.x < global_position.x

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	else:
		_shoot_burst()
		_finish_attack()


func _on_sprite_frame_changed() -> void:
	if not boss_active:
		return

	if not attacking:
		return

	if sprite.animation != "attack":
		return

	if has_shot_this_attack:
		return

	if sprite.frame >= attack_shoot_frame:
		has_shot_this_attack = true
		_shoot_burst()


func _on_sprite_animation_finished() -> void:
	if not boss_active:
		return

	if not attacking:
		return

	if sprite.animation == "attack":
		_finish_attack()


func _shoot_burst() -> void:
	if espectro_scene == null:
		push_error("ERROR: No asignaste Espectro.tscn en Espectro Scene.")
		return

	if player == null:
		return

	if projectile_spawn == null:
		return

	var spawn_position := projectile_spawn.global_position
	var base_direction := (player.global_position - spawn_position).normalized()

	for i in range(burst_count):
		if not boss_active:
			return

		var angle_offset := 0.0

		if burst_count == 1:
			angle_offset = 0.0
		else:
			var middle := float(burst_count - 1) / 2.0
			angle_offset = deg_to_rad((float(i) - middle) * burst_spread_degrees)

		var final_direction := base_direction.rotated(angle_offset)

		_create_espectro(spawn_position, final_direction)

		await get_tree().create_timer(burst_delay).timeout

	print("El alma del padre lanzó una ráfaga")


func _create_espectro(spawn_position: Vector2, direction: Vector2) -> void:
	var espectro = espectro_scene.instantiate()
	get_parent().add_child(espectro)

	if espectro.has_method("setup_direction"):
		espectro.setup_direction(spawn_position, direction)
	elif espectro.has_method("setup"):
		espectro.setup(spawn_position, spawn_position + direction * 100)
	else:
		push_error("ERROR: El script espectro.gd necesita setup_direction() o setup().")


func _finish_attack() -> void:
	if not boss_active:
		return

	attacking = false
	has_shot_this_attack = false

	_play_idle_animation()
	_choose_new_target()
	_start_attack_timer()


func _play_idle_animation() -> void:
	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	print("El alma del padre recibió daño: ", amount)
	print("Vida del jefe: ", current_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()


func die() -> void:
	print("El alma del padre fue derrotado")

	boss_defeated.emit()
	stop_boss_fight()
	queue_free()
