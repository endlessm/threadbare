# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@export var speed: float = 48.0
@export var defeat_on_touch: bool = true
@export var patrol_path: PathFollow2D
@export var chase_radius: float = 400.0
@export var shake_radius: float = 140.0
@export var shake_intensity: float = 6.0
@export var shake_interval: float = 0.8

var _shake_timer: Timer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var touch_area: Area2D = $TouchArea


func _ready() -> void:
	if sprite.sprite_frames:
		sprite.play()
	touch_area.body_entered.connect(_on_body_entered)

	_shake_timer = Timer.new()
	_shake_timer.wait_time = shake_interval
	add_child(_shake_timer)
	_shake_timer.timeout.connect(_do_shake)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var chasing := (
		player != null
		and global_position.distance_to(player.global_position) <= chase_radius
		and _has_line_of_sight(player.global_position)
	)

	var target := Vector2.ZERO
	if chasing:
		target = player.global_position
	elif patrol_path:
		patrol_path.progress += speed * delta
		target = patrol_path.global_position

	if target != Vector2.ZERO:
		var to_target := target - global_position
		velocity = to_target.normalized() * speed if to_target.length() > 2.0 else Vector2.ZERO
		if absf(velocity.x) > 0.1:
			sprite.flip_h = velocity.x < 0.0
	move_and_slide()

	_update_shake(player)


func _has_line_of_sight(to: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, to, collision_mask)
	query.exclude = [self]
	return space_state.intersect_ray(query).is_empty()


func _update_shake(player: Node2D) -> void:
	if player == null:
		return
	var near := global_position.distance_to(player.global_position) <= shake_radius
	if near and _shake_timer.is_stopped():
		_do_shake()
		_shake_timer.start()
	elif not near and not _shake_timer.is_stopped():
		_shake_timer.stop()


func _do_shake() -> void:
	if CameraShake.shaker == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	CameraShake.shaker.target = cam
	CameraShake.shaker.shake(shake_intensity, shake_interval * 1.5)


func _on_body_entered(body: Node2D) -> void:
	if defeat_on_touch and body.is_in_group(&"player") and body.has_method("defeat"):
		body.defeat()
