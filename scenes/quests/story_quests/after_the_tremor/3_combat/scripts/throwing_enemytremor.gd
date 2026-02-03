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
			_attack_random()

		2:
			if randf() < 0.2:
				_attack_both()
			else:
				_attack_random()

		3:
			if randf() < 0.6:
				_attack_both()
			else:
				_attack_random()

	_set_target_position()


func _attack_random() -> void:
	var target := target_charlie if randi() % 2 == 0 else target_bryan
	shoot_projectile_at(target)


func _attack_both() -> void:
	shoot_projectile_at(target_charlie)
	# Pequeña espera o inmediato
	shoot_projectile_at(target_bryan)


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
