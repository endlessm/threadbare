# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EchoAbyssBoss
extends CharacterBody2D

enum State { IDLE, JUMPING, CHASING, ATTACKING, DEFEATED }

@export var max_health: float = 100.0
@export var projectile_scene: PackedScene
@export var patrol_path: Path2D
@export var jump_height: float = 150.0
@export var jump_duration: float = 1.2
@export var shoot_cooldown: float = 2.0
@export var melee_range: float = 90.0
@export var melee_cooldown: float = 1.5
@export var chase_speed: float = 120.0
@export var rock_spawn_period: float = 2.0
@export var phase2_jump_cooldown := 2.0
@export var projectile_color: Color = Color.WHITE
@export var rock_color: Color = Color(0.741, 0.301, 0.087, 1.0)
@export var essence_reward: int = 50

var health: float = max_health
var current_state: State = State.IDLE
var current_patrol_idx: int = 0
var _player: EchoAbyssPlayer
var _is_jumping: bool = false
var _shoot_timer: float = 0.0
var _melee_timer: float = 0.0
var _rock_timer: float = 0.0
var _is_defeated: bool = false
var _is_phase2_jumping := false
var _phase2_jump_timer := 0.0
# Flag para detener el loop de saltos de fase 1 al transicionar a fase 2
var _phase1_active: bool = false
var intro_finished := false

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hit_box: Area2D = %HitBox
@onready var projectile_marker: Marker2D = %ProjectileMarker
@onready var health_bar: TextureProgressBar = find_child("BossHealthBar", true, false)

func _ready() -> void:
	health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = true

	# Find player
	_player = get_tree().get_first_node_in_group("player") as EchoAbyssPlayer
	
	# Connect HitBox body entered
	if hit_box:
		hit_box.body_entered.connect(_on_hit_box_body_entered)

func _process(delta: float) -> void:
	if not intro_finished:
		return
	
	if _is_defeated:
		return

	if not is_instance_valid(_player):
		return

	# State machine and updates
	if health > 50:
		# Phase 1
		_process_phase_1(delta)
	else:
		# Phase 2
		_process_phase_2(delta)

func begin_fight() -> void:
	if intro_finished:
		return

	intro_finished = true
	_start_phase_1()

func _start_phase_1() -> void:
	current_state = State.IDLE
	_shoot_timer = shoot_cooldown
	_phase1_active = true
	_do_next_jump()

func _do_next_jump() -> void:
	# Salir si el boss fue derrotado o si la fase 1 ya no está activa
	if _is_defeated or not _phase1_active or health <= 50:
		return

	if not patrol_path or patrol_path.curve.point_count < 2:
		return

	# Choose next patrol point
	current_patrol_idx = (current_patrol_idx + 1) % patrol_path.curve.point_count
	var target_local = patrol_path.curve.get_point_position(current_patrol_idx)
	var target_global = patrol_path.to_global(target_local)

	_is_jumping = true
	current_state = State.JUMPING
	animation_player.play(&"walk")

	var start_pos = global_position
	var tween = create_tween().set_parallel(true)

	# Parabolic jump arc tween
	tween.tween_method(func(t: float):
		if _is_defeated:
			return
		var horizontal_pos = start_pos.lerp(target_global, t)
		var vertical_offset = Vector2.UP * sin(t * PI) * jump_height
		global_position = horizontal_pos + vertical_offset
	, 0.0, 1.0, jump_duration)

	await tween.finished
	_is_jumping = false

	# Verificar de nuevo tras el await por si el estado cambió
	if _is_defeated or not _phase1_active:
		return

	# Capturamos la posición del player en este instante exacto para el disparo
	_shoot_projectile()

	# Wait a short moment then jump again
	current_state = State.IDLE
	animation_player.play(&"idle")
	await get_tree().create_timer(1.0).timeout
	_do_next_jump()

func _process_phase_1(_delta: float) -> void:
	# Jumping handles its own movement. We just check if we should shoot.
	pass

func _jump_to_player() -> void:
	if _is_phase2_jumping or _is_defeated:
		return

	_is_phase2_jumping = true

	current_state = State.JUMPING
	animation_player.play(&"walk")

	var start_pos = global_position
	var target_global = _player.global_position

	var tween = create_tween().set_parallel(true)

	tween.tween_method(
		func(t: float):
			if _is_defeated:
				return

			var horizontal_pos = start_pos.lerp(target_global, t)
			var vertical_offset = Vector2.UP * sin(t * PI) * jump_height

			global_position = horizontal_pos + vertical_offset,
		0.0,
		1.0,
		jump_duration
	)

	await tween.finished

	_is_phase2_jumping = false

	if _is_defeated:
		return

	current_state = State.ATTACKING

	if global_position.distance_to(_player.global_position) <= melee_range:
		_perform_melee_attack()
	_shoot_projectile()

	animation_player.play(&"idle")
	
func _process_phase_2(delta: float) -> void:
	if not _player:
		return
	
	#Orientacion de boss
	var dir_to_player := global_position.direction_to(_player.global_position)
	
	if dir_to_player.x < 0:
		scale.x = 1
	else:
		scale.x = -1
		
	# Phase 2: Spawns falling rocks periodically and chases player for melee
	_rock_timer += delta
	if _rock_timer >= rock_spawn_period:
		_rock_timer = 0.0
		_spawn_falling_rock()
		
	_phase2_jump_timer += delta
	if _phase2_jump_timer >= phase2_jump_cooldown:
		_phase2_jump_timer = 0.0
		_jump_to_player()

func _shoot_projectile() -> void:
	if not projectile_scene or not is_instance_valid(_player):
		return

	# Spawn projectile towards player
	var projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		return

	projectile.can_hit_enemy = false
	projectile.can_hit_player = true
	projectile.color = projectile_color
	
	#print(projectile.get_script().resource_path)
	
	var dir = projectile_marker.global_position.direction_to(_player.global_position)
	projectile.direction = dir
	projectile.global_position = projectile_marker.global_position + dir * 20.0
	projectile.speed = 200.0
	projectile.duration = 6.0
	
	get_tree().current_scene.add_child(projectile)

func _spawn_falling_rock() -> void:
	if not projectile_scene or not is_instance_valid(_player):
		return

	# Instantiate a projectile behaving as a falling rock
	var rock = projectile_scene.instantiate() as Projectile
	if rock == null:
		return

	rock.can_hit_enemy = false
	rock.can_hit_player = true
	# Give it a rock-like color (dark grey/brown)
	rock.color = rock_color
	
	# Spawn above player's current view
	var spawn_x = _player.global_position.x + randf_range(-300.0, 300.0)
	var spawn_y = _player.global_position.y - 350.0
	
	rock.global_position = Vector2(spawn_x, spawn_y)
	rock.direction = Vector2.DOWN
	rock.speed = 180.0
	rock.duration = 5.0
	
	# IMPORTANTE: Las rocas NO deben colisionar con el cuerpo del boss (capa 1)
	# para evitar que reboten en él antes de llegar al player.
	# Usamos la máscara 80 (WALLS + PLAYERS_HITBOX) sin incluir PLAYERS(1).
	# La detección de daño al player se hace vía el HitBox Area2D del player.
	rock.set_collision_mask_value(1, false)
	
	get_tree().current_scene.add_child(rock)

func _perform_melee_attack() -> void:
	if not is_instance_valid(_player) or _is_defeated:
		return
	animation_player.play(&"attack")
	
	# Wait brief moment for swing contact
	await get_tree().create_timer(0.3).timeout
	if _is_defeated:
		return
		
	var dist = global_position.distance_to(_player.global_position)
	if dist <= melee_range + 20.0:
		_player.take_damage(1)
		
	animation_player.queue(&"idle")

func take_damage(amount: float) -> void:
	if _is_defeated:
		return
		
	health = max(0.0, health - amount)
	if health_bar:
		health_bar.value = health

	animation_player.play(&"got hit")
	animation_player.queue(&"idle")

	if health <= 0.0:
		_defeat()
	elif health <= 50.0 and current_state != State.CHASING and current_state != State.ATTACKING:
		# Detener el loop de fase 1 antes de transicionar
		_phase1_active = false
		_is_jumping = false
		current_state = State.CHASING

func _on_hit_box_body_entered(body: Node2D) -> void:
	if _is_defeated:
		return
	if body is Projectile:
		if not body.can_hit_enemy:
			return
		take_damage(10.0)
		body.queue_free()

func _defeat() -> void:
	_is_defeated = true
	_phase1_active = false
	current_state = State.DEFEATED
	velocity = Vector2.ZERO
	animation_player.play(&"defeated")
	
	# Hide health bar
	if health_bar:
		health_bar.visible = false
	
	# Wait for defeat animation and trigger victory condition
	await animation_player.animation_finished
	
	if is_instance_valid(_player) and _player.has_method("add_essence"):
		_player.add_essence(essence_reward)
		if(_player.get_current_health()<_player.get_max_health()):
			_player.set_health(1)
	
	queue_free()
