# player.gd
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends CharacterBody2D

const MOVE_SPEED: float = 250.0

signal letra_iluminada(node: Node2D)
signal letra_oscurecida(node: Node2D)

@onready var detection_area: Area2D               = %DetectionArea
@onready var sight_ray_cast: RayCast2D            = %SightRayCast
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer    = $AnimationPlayer

var _last_direction: Vector2 = Vector2.RIGHT
var _input_dir: Vector2 = Vector2.ZERO

const LOOK_AT_TURN_SPEED: float = 10.0

func _ready() -> void:
	add_to_group("player")
	detection_area.area_entered.connect(_on_detection_area_area_entered)
	detection_area.area_exited.connect(_on_detection_area_area_exited)

func _physics_process(delta: float) -> void:
	# Si la UI tiene foco, el jugador no se mueve
	var focus_owner = get_viewport().gui_get_focus_owner()
	var ui_has_focus = focus_owner != null

	if ui_has_focus:
		velocity = Vector2.ZERO
		move_and_slide()
		animation_player.play(&"idle")
		return

	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir.x = 1.0
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1.0
		animated_sprite_2d.flip_h = true
	if Input.is_action_pressed("ui_up"):
		input_dir.y = -1.0
	elif Input.is_action_pressed("ui_down"):
		input_dir.y = 1.0

	velocity = input_dir.normalized() * MOVE_SPEED
	move_and_slide()

	if not input_dir.is_zero_approx():
		_last_direction = input_dir.normalized()

	var target_angle := _last_direction.angle()
	detection_area.rotation = rotate_toward(
		detection_area.rotation,
		target_angle,
		delta * LOOK_AT_TURN_SPEED
	)

	_update_animation()

func _update_animation() -> void:
	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")

func _on_detection_area_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hidden_letter"):
		return
	if _is_sight_to_point_blocked(area.global_position):
		return
	letra_iluminada.emit(area)

func _on_detection_area_area_exited(area: Area2D) -> void:
	if not area.is_in_group("hidden_letter"):
		return
	letra_oscurecida.emit(area)

func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()
