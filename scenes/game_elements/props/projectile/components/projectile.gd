# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Projectile
extends RigidBody2D
## A projectile that can fill matching [FillingBarrel]s.
##
## @tutorial: https://github.com/endlessm/threadbare/discussions/1323
##
## This is a piece of the fill-matching mechanic.
## [br][br]
## The projectile has a [member label] and optionally a [member color]
## to tint it.
## When the projectile collides with a [FillingBarrel] and both labels match,
## it calls [member FillingBarrel.increment()] and is removed.
## [br][br]
## The projectile will live in the scene until [member duration_timer] times up.
## When the projectile collides with anything, this timer is resetted, so the
## projectile life is expanded.

## The projectile can fill barrels with the matching label.
@export var label: String = "???"

## Optional color. Use it together with the label to make a color-matching game.
@export var color: Color:
	set = _set_color

## The projectile SpriteFrames. It should have a looping animation in autoplay.
@export var sprite_frames: SpriteFrames = preload("uid://b00dcfe4dtvkh"):
	set = _set_sprite_frames

## Sound that plays when the projectile hits something.
@export var hit_sound_stream: AudioStream:
	set = _set_hit_sound_stream

## Whether this projectile hits the player.
@export var can_hit_player: bool = true:
	set = _set_can_hit_player

## Whether this projectile hits the enemies.
@export var can_hit_enemy: bool = false:
	set = _set_can_hit_enemy

@export_group("Movement")

## The speed of the initial impulse and the bouncing impulse.
@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var speed: float = 30.0

## The initial direction.
@export var direction: Vector2 = Vector2(0, -1):
	set = _set_direction

## The life span of the projectile.
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var duration: float = 5.0

## If set, the projectile will constantly adjust itself to target this node. It will still start
## moving in the initial [member direction].
@export var node_to_follow: Node2D = null

@export_group("FXs")

## A small visual effect used when the projectile collides with things.
@export var small_fx_scene: PackedScene

## A big visual effect used when the projectile explodes.
@export var big_fx_scene: PackedScene

## A scene with a trail particles visual effect. It should contain a [class GPUParticles2D] as
## root node. When the projectile gets hit, the [member GPUParticles2D.amount_ratio] is set to 1.
@export var trail_fx_scene: PackedScene

var _trail_particles: GPUParticles2D

@onready var visible_things: Node2D = %VisibleThings
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var trail_fx_marker: Marker2D = %TrailFXMarker

## How long the projectile lives in the scene.
## [br][br]
## This timer is restarted each time the projectile collides with anything.
## So the life of the projectile is extended in each collision.
@onready var duration_timer: Timer = %DurationTimer

@onready var hit_sound: AudioStreamPlayer2D = %HitSound


func _set_color(new_color: Color) -> void:
	color = new_color
	modulate = color if color else Color.WHITE


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	animated_sprite_2d.play(animated_sprite_2d.animation)


func _set_hit_sound_stream(new_hit_sound_stream: AudioStream) -> void:
	hit_sound_stream = new_hit_sound_stream
	if not is_node_ready():
		await ready
	hit_sound.stream = hit_sound_stream


func _set_direction(new_direction: Vector2) -> void:
	if not new_direction.is_normalized():
		direction = new_direction.normalized()
	else:
		direction = new_direction


func _set_can_hit_player(new_can_hit_player: bool) -> void:
	can_hit_player = new_can_hit_player
	set_collision_mask_value(Enums.CollisionLayers.PLAYERS_HITBOX, can_hit_player)


func _set_can_hit_enemy(new_can_hit_enemy: bool) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(Enums.CollisionLayers.ENEMIES_HITBOX, can_hit_enemy)


func _ready() -> void:
	if trail_fx_scene:
		_trail_particles = trail_fx_scene.instantiate()
		trail_fx_marker.add_child(_trail_particles)

	_set_color(color)
	_set_sprite_frames(sprite_frames)
	duration_timer.wait_time = duration
	duration_timer.start()
	var impulse: Vector2 = direction * speed
	apply_impulse(impulse)


func _process(_delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	if node_to_follow:
		var direction_to_target: Vector2 = global_position.direction_to(
			node_to_follow.global_position
		)
		var force: Vector2 = direction_to_target * speed
		constant_force = force


## Add a small effect scene to the current scene in the current position.
func add_small_fx() -> void:
	if not small_fx_scene:
		return
	var small_fx: Node2D = small_fx_scene.instantiate()
	if color:
		small_fx.modulate = color
	get_tree().current_scene.add_child(small_fx)
	small_fx.global_position = global_position


func _on_body_entered(body: Node2D) -> void:
	add_small_fx()
	duration_timer.start()
	if body.owner is FillingBarrel:
		var filling_barrel: FillingBarrel = body.owner as FillingBarrel
		if filling_barrel.label == label:
			filling_barrel.increment()
			queue_free()


func got_hit(player: Player) -> void:
	add_small_fx()
	duration_timer.start()
	var hit_speed := 100.0
	var hit_vector: Vector2 = player.global_position.direction_to(global_position) * hit_speed
	hit_sound.play()
	animated_sprite_2d.speed_scale = 2
	if _trail_particles:
		_trail_particles.amount_ratio = 1.
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)


func explode() -> void:
	if big_fx_scene:
		var big_fx: Node2D = big_fx_scene.instantiate()
		if color:
			big_fx.modulate = color
		get_tree().current_scene.add_child(big_fx)
		big_fx.global_position = global_position
	queue_free()


func _on_duration_timer_timeout() -> void:
	explode()


## Remove the ball from the scene after the goal is reached.
## Wait a short random time and then explode.
func remove() -> void:
	await get_tree().create_timer(randf_range(0., 3.)).timeout
	explode()
