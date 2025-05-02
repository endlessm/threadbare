# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
## Enemy that throws projectiles to the player.
class_name ThrowingEnemy
extends CharacterBody2D

enum State { IDLE, WALKING, ATTACKING, DEFEATED }

const PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/game_elements/props/projectile/projectile.tscn"
)

## When targetting the next walking position, skip this slice of the circle.
const WALK_TARGET_SKIP_ANGLE: float = PI / 4.

## When targetting the next walking position, skip an inner circle. The radius of the inner
## circle is this proportion of the [member walking_range].
const WALK_TARGET_SKIP_RANGE: float = 0.25

## The period of time between throwing projectiles.
@export_range(0.1, 10., 0.1, "or_greater", "suffix:s") var throwing_period: float = 5.0

## Use this to have 2 enemies throwing projectiles alternatively and at the same pace
## (same [member throwing_period]).
@export var odd_shoot: bool = false

## Whether the enemy starts attacking or walking automatically. If false, make sure
## to call [method start].
@export var autostart: bool = false

@export_group("Projectile", "projectile")

## The speed of the projectile initial impulse and the projectile bouncing impulse.
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s")
var projectile_speed: float = 30.0

## The life span of the projectile.
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var projectile_duration: float = 5.0

## If true, the projectile will constantly adjust itself to target the player.
@export var projectile_follows_player: bool = false

## A small visual effect used when the projectile collides with things.
@export var projectile_small_fx_scene: PackedScene

## A big visual effect used when the projectile explodes.
@export var projectile_big_fx_scene: PackedScene

@export_group("Walking", "walking")

## If this is not zero, the enemy walks this amount of time between being idle and
## throwing. If it is bigger than [member throwing_period], the enemy walks all the
## time.
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var walking_time: float = 0.0:
	set(value):
		walking_time = value
		queue_redraw()

## The range that the enemy is allowed to walk. This is the radius of a circle that
## has the initial position as center. The range is visible in the editor when
## [member walking_time] is not zero.
@export_range(0., 500., 1., "or_greater", "suffix:m") var walking_range: float = 300.0:
	set(value):
		walking_range = value
		queue_redraw()

## The moving speed of the enemy when walking.
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var walking_speed: float = 50.0

## The label of each projectile thrown will be a random choice from this array.
## So if a label appears more than once, this will increase the chance that it is thrown.
var allowed_labels: Array[String] = ["???"]

## Optional mapping of color per label. This is used to tint projectiles to make a
## color-matching game.
var color_per_label: Dictionary[String, Color]

var _initial_position: Vector2
var _target_position: Vector2
var _is_attacking: bool
var _is_defeated: bool

@onready var timer: Timer = %Timer
@onready var projectile_marker: Marker2D = %ProjectileMarker
@onready var hit_box: Area2D = %HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_initial_position = position
	if Engine.is_editor_hint():
		return
	var player: Player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var direction: Vector2 = projectile_marker.global_position.direction_to(
			player.global_position
		)
		scale.x = 1 if direction.x < 0 else -1
	if autostart:
		start()


func _draw() -> void:
	if walking_time == 0 or walking_range == 0:
		return
	if Engine.is_editor_hint() or get_tree().is_debugging_collisions_hint():
		draw_circle(_initial_position - position, walking_range, Color(0.0, 1.0, 1.0, 0.3))
		draw_circle(
			_initial_position - position,
			walking_range * WALK_TARGET_SKIP_RANGE,
			Color(0.0, 0.0, 0.0, 0.3)
		)
		if get_tree().is_debugging_collisions_hint():
			## Only when playing with collision shapes visible, draw a dot for the target position:
			draw_circle(_target_position - position, 10., Color(1.0, 0.0, 0.0, 0.7))


func _get_state() -> State:
	if _is_defeated:
		return State.DEFEATED
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
		State.ATTACKING, State.DEFEATED:
			return
		State.IDLE:
			if animated_sprite_2d.animation not in [&"attack anticipation", &"attack"]:
				animation_player.play("idle")
			return
		State.WALKING:
			velocity = _get_velocity()
			move_and_slide()
			if get_tree().is_debugging_collisions_hint():
				# Update the debug shapes when the position changes:
				queue_redraw()
			if not velocity.is_zero_approx():
				animated_sprite_2d.play(&"walk")


func _set_target_position() -> void:
	var current_angle := _initial_position.angle_to_point(position)
	var start_angle := current_angle + WALK_TARGET_SKIP_ANGLE / 2.
	var end_angle := 2 * PI - current_angle - WALK_TARGET_SKIP_ANGLE / 2.
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
	animation_player.play("attack anticipation")
	await animation_player.animation_finished
	animated_sprite_2d.play(&"attack")
	if not allowed_labels:
		_is_attacking = false
		return
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = projectile_marker.global_position.direction_to(player.global_position)
	scale.x = 1 if projectile.direction.x < 0 else -1
	projectile.label = allowed_labels.pick_random()
	if projectile.label in color_per_label:
		projectile.color = color_per_label[projectile.label]
	projectile.global_position = (projectile_marker.global_position + projectile.direction * 20.)
	if projectile_follows_player:
		projectile.node_to_follow = player
	if projectile_small_fx_scene:
		projectile.small_fx_scene = projectile_small_fx_scene
	if projectile_big_fx_scene:
		projectile.big_fx_scene = projectile_big_fx_scene
	projectile.speed = projectile_speed
	projectile.duration = projectile_duration
	get_tree().current_scene.add_child(projectile)
	_set_target_position()
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play(&"idle")
	_is_attacking = false


func _on_got_hit(body: Node2D) -> void:
	if body is Projectile and not body.can_hit_enemy:
		return
	body.queue_free()
	animation_player.play(&"got hit")


## Start attacking and/or walking. The enemy will be idle until this is called.
## See [member autostart].
func start() -> void:
	timer.wait_time = throwing_period
	timer.timeout.connect(_on_timeout)
	hit_box.body_entered.connect(_on_got_hit)
	if odd_shoot:
		await get_tree().create_timer(throwing_period / 2).timeout
	timer.start()
	_initial_position = position
	_set_target_position()


## Play a remove animation and then remove the enemy from the scene.
func remove() -> void:
	timer.stop()
	_is_defeated = true
	animated_sprite_2d.play(&"defeated")
	await animated_sprite_2d.animation_finished
	queue_free()
