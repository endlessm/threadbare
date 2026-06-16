# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D
class_name EchoAbyssWanderingNpc

@export var walk_speed: float = 80.0
@export var sprite_frames: SpriteFrames:
	set(new_sprite_frames):
		sprite_frames = new_sprite_frames
		if _animated_sprite and sprite_frames:
			_animated_sprite.sprite_frames = sprite_frames

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

var _direction: Vector2 = Vector2.ZERO
var _change_timer: float = 0.0

func _ready() -> void:
	if sprite_frames:
		_animated_sprite.sprite_frames = sprite_frames
	_pick_new_direction()
	_update_animation()

func _physics_process(delta: float) -> void:
	_change_timer -= delta
	if _change_timer <= 0.0:
		_pick_new_direction()

	velocity = _direction * walk_speed
	var collided := move_and_slide()
	
	if collided and get_slide_collision_count() > 0:
		# Collided with wall or obstacle, pick new direction immediately
		_pick_new_direction()

func _pick_new_direction() -> void:
	_change_timer = randf_range(2.0, 5.0)
	# 70% chance of walking, 30% chance of standing idle
	if randf() < 0.3:
		_direction = Vector2.ZERO
	else:
		var angle := randf() * TAU
		_direction = Vector2.from_angle(angle)
	_update_animation()

func _update_animation() -> void:
	if not _animated_sprite or not _animated_sprite.sprite_frames:
		return
	
	if _direction.is_zero_approx():
		if _animated_sprite.sprite_frames.has_animation(&"idle"):
			_animated_sprite.play(&"idle")
	else:
		if _animated_sprite.sprite_frames.has_animation(&"walk"):
			_animated_sprite.play(&"walk")
		elif _animated_sprite.sprite_frames.has_animation(&"idle"):
			_animated_sprite.play(&"idle")
		
		# Flip sprite based on direction
		if _direction.x < 0:
			_animated_sprite.flip_h = true
		elif _direction.x > 0:
			_animated_sprite.flip_h = false

# Custom method called by devourer when eaten
func devour() -> void:
	# Disable collisions immediately to prevent double devouring
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	
	# Play fade out animation
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
