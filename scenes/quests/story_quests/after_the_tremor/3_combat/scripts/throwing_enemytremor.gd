# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ThrowingEnemy

@export var target_charlie: Node2D
@export var target_bryan: Node2D
@export var health_barrel: Node2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var current_phase: int = 1

func _ready():
	super._ready()


func _process(delta):
	super._process(delta)
	_check_phase()

func _check_phase():
	if not health_barrel: return
	

	var hits_taken = health_barrel._amount 
	var max_hits = health_barrel.needed_amount
	

	if hits_taken < max_hits * 0.33:
		current_phase = 1
		throwing_period = 2.5 # Lento
		

	elif hits_taken < max_hits * 0.66:
		current_phase = 2
		throwing_period = 1.8 # Medio
		

	else:
		current_phase = 3
		throwing_period = 1.2 


func shoot_projectile() -> void:

	match current_phase:
		1:

			var target = _choose_random_target()
			_spawn_bullet(target)
			
		2:

			if randf() < 0.2: 
				_attack_both()
			else:
				_spawn_bullet(_choose_random_target())
				
		3:

			if randf() < 0.6: 
				_attack_both()
			else:
				_spawn_bullet(_choose_random_target())

	_set_target_position()


func _choose_random_target() -> Node2D:
	if randi() % 2 == 0:
		return target_charlie
	else:
		return target_bryan


func _attack_both():
	_spawn_bullet(target_charlie)
	# Pequeña espera o inmediato
	_spawn_bullet(target_bryan)


func _spawn_bullet(target_node: Node2D):
	if not is_instance_valid(target_node): return
	
	var projectile = projectile_scene.instantiate()
	

	projectile.direction = projectile_marker.global_position.direction_to(target_node.global_position)
	
	scale.x = 1 if projectile.direction.x < 0 else -1
	

	projectile.label = allowed_labels.pick_random()
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	
	projectile.global_position = projectile_marker.global_position + projectile.direction * distance
	

	if projectile_follows_player:
		projectile.node_to_follow = target_node 
		

	projectile.sprite_frames = projectile_sprite_frames
	projectile.hit_sound_stream = projectile_hit_sound_stream
	projectile.small_fx_scene = projectile_small_fx_scene
	projectile.big_fx_scene = projectile_big_fx_scene
	projectile.trail_fx_scene = projectile_trail_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	
	get_tree().current_scene.add_child(projectile)
func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
