# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InkDrinker
extends CharacterBody2D

enum State {
	IDLE,
	WALKING,
	ATTACKING,
}

const INK_BLOB: PackedScene = preload("res://scenes/ink_combat/ink_blob/ink_blob.tscn")

## When targetting the next walking position, skip this slice of the circle.
const WALK_TARGET_SKIP_ANGLE: float = PI / 4.

## When targetting the next walking position, skip an inner circle. The radius of the inner
## circle is this proportion of the [member walking_range].
const WALK_TARGET_SKIP_RANGE: float = 0.25

@export var autostart: bool = false
@export var odd_shoot: bool = false
@export var ink_follows_player: bool = false
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var ink_speed: float = 30.0
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var ink_duration: float = 5.0

## The period of time between throwing ink.
@export_range(0.1, 10., 0.1, "or_greater", "suffix:s") var ink_period: float = 5.0

## If this is not zero, the ink drinker walks this amount of time between being idle and
## throwing ink. If it is bigger than [member ink_period], the ink drinker walks all the
## time.
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var walking_time: float = 0.0:
	set(value):
		walking_time = value
		queue_redraw()

## The range that the ink drinker is allowed to walk. This is the radius of a circle that
## has the initial position as center. The range is visible in the editor when
## [member walking_time] is not zero.
@export_range(0., 500., 1., "or_greater", "suffix:m") var walking_range: float = 300.0:
	set(value):
		walking_range = value
		queue_redraw()

## The moving speed of the ink drinker when walking.
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var walking_speed: float = 50.0

var _initial_position: Vector2
var _target_position: Vector2
var _is_attacking: bool

@onready var timer: Timer = %Timer
@onready var ink_blob_marker: Marker2D = %InkBlobMarker
@onready var hit_box: Area2D = %HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if autostart:
		start()


func _draw() -> void:
	if walking_time == 0 or walking_range == 0:
		return
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, walking_range, Color(0.0, 1.0, 1.0, 0.3))
		draw_circle(Vector2.ZERO, walking_range * WALK_TARGET_SKIP_RANGE, Color(0.0, 0.0, 0.0, 0.3))


func _get_state() -> State:
	if _is_attacking:
		return State.ATTACKING
	if is_zero_approx(walking_time) or is_zero_approx(walking_range):
		return State.IDLE
	if timer.is_stopped() or timer.paused:
		return State.IDLE
	var walk_start_time: float
	var walk_end_time: float
	if walking_time > timer.wait_time:
		walk_start_time = 0.0
		walk_end_time = timer.wait_time
	else:
		walk_start_time = (timer.wait_time - walking_time) / 2
		walk_end_time = walk_start_time + walking_time
	if walk_end_time < timer.time_left or timer.time_left < walk_start_time:
		return State.IDLE
	return State.WALKING


func _get_velocity() -> Vector2:
	var delta: Vector2 = _target_position - position
	if delta.is_zero_approx():
		return Vector2.ZERO
	return position.direction_to(_target_position) * min(delta.length(), walking_speed)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var state: State = _get_state()
	match state:
		State.ATTACKING:
			return
		State.IDLE:
			if animated_sprite_2d.animation not in [&"attack anticipation", &"attack"]:
				animated_sprite_2d.play(&"idle")
			return
		State.WALKING:
			velocity = _get_velocity()
			move_and_slide()
			if not velocity.is_zero_approx():
				animated_sprite_2d.play(&"walk")


func _set_target_position() -> void:
	var current_angle = _initial_position.angle_to_point(position)
	var start_angle = current_angle + WALK_TARGET_SKIP_ANGLE / 2.
	var end_angle = 2 * PI - current_angle - WALK_TARGET_SKIP_ANGLE / 2.
	_target_position = (
		_initial_position
		+ (
			Vector2.LEFT.rotated(randf_range(start_angle, end_angle))
			* walking_range
			* randf_range(WALK_TARGET_SKIP_RANGE, 1.0)
		)
	)


func _on_timeout() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	_is_attacking = true
	animated_sprite_2d.play(&"attack anticipation")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play(&"attack")
	var ink_blob: InkBlob = INK_BLOB.instantiate()
	ink_blob.direction = ink_blob_marker.global_position.direction_to(player.global_position)
	ink_blob.ink_color_name = randi_range(0, 3) as InkBlob.InkColorNames
	ink_blob.global_position = (ink_blob_marker.global_position + ink_blob.direction * 20.)
	if ink_follows_player:
		ink_blob.node_to_follow = player
	ink_blob.speed = ink_speed
	ink_blob.duration = ink_duration
	get_tree().current_scene.add_child(ink_blob)
	_set_target_position()
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play(&"idle")
	_is_attacking = false


func _on_got_hit(body: Node2D) -> void:
	if body is InkBlob and not body.can_hit_enemy:
		return
	body.queue_free()
	animation_player.play(&"got hit")


func start() -> void:
	timer.wait_time = ink_period
	timer.timeout.connect(_on_timeout)
	hit_box.body_entered.connect(_on_got_hit)
	if odd_shoot:
		await get_tree().create_timer(ink_period / 2).timeout
	timer.start()
	_initial_position = position
	_set_target_position()


func remove() -> void:
	timer.stop()
	animation_player.play(&"remove")
	await animation_player.animation_finished
	queue_free()
