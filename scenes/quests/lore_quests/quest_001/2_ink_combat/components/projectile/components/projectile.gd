# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## A RigidBody2D that can be thrown between enemies and player. It has a label too, and it can
## be used to fill barrels with the matching label.
class_name Projectile
extends RigidBody2D

# TODO: Replace colors with labels:
enum InkColorNames {
	CYAN = 0,
	MAGENTA = 1,
	YELLOW = 2,
	BLACK = 3,
}

const PLAYER_HITBOX_LAYER: int = 6
const ENEMY_HITBOX_LAYER: int = 7

const INK_COLORS: Dictionary = {
	InkColorNames.CYAN: Color(0., 1., 1.),
	InkColorNames.MAGENTA: Color(1., 0., 1.),
	InkColorNames.YELLOW: Color(1., 1., 0.),
	InkColorNames.BLACK: Color(0.2, 0.2, 0.2),
}

@export_range(10., 100., 5., "or_greater", "or_less", "suffix:m/s") var speed: float = 30.0
@export var direction: Vector2 = Vector2(0, -1):
	set = _set_direction
@export var can_hit_enemy: bool = false:
	set = _set_can_hit_enemy
@export var ink_color_name: InkColorNames = InkColorNames.CYAN
@export_range(0., 10., 0.1, "or_greater", "suffix:s") var duration: float = 5.0
@export var node_to_follow: Node2D = null

## A small visual effect used when the projectile collides with things.
@export var small_fx_scene: PackedScene = preload(
	"res://scenes/quests/lore_quests/quest_001/2_ink_combat/components/splash/splash.tscn"
)

## A big visual effect used when the projectile explodes.
@export var big_fx_scene: PackedScene = preload(
	"res://scenes/quests/lore_quests/quest_001/2_ink_combat/components/big_splash/big_splash.tscn"
)

@onready var visible_things: Node2D = %VisibleThings
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D
@onready var duration_timer: Timer = %DurationTimer
@onready var hit_sound: AudioStreamPlayer2D = %HitSound


func _set_direction(new_direction: Vector2) -> void:
	if not new_direction.is_normalized():
		direction = new_direction.normalized()
	else:
		direction = new_direction


func _set_can_hit_enemy(new_can_hit_enemy: bool) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(PLAYER_HITBOX_LAYER, not can_hit_enemy)
	set_collision_mask_value(ENEMY_HITBOX_LAYER, can_hit_enemy)
	animation_player.speed_scale = 2 if can_hit_enemy else 1
	gpu_particles_2d.amount_ratio = 1. if can_hit_enemy else .1


func _ready() -> void:
	var color: Color = INK_COLORS[ink_color_name]
	visible_things.modulate = color
	duration_timer.wait_time = duration
	duration_timer.start()
	var impulse: Vector2 = direction * speed
	apply_impulse(impulse)
	hit_sound.play()


func _process(_delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	if node_to_follow:
		var direction_to_target: Vector2 = global_position.direction_to(
			node_to_follow.global_position
		)
		var force: Vector2 = direction_to_target * speed
		constant_force = force


func add_small_fx() -> void:
	var small_fx: Node2D = small_fx_scene.instantiate()
	small_fx.ink_color_name = ink_color_name
	get_tree().current_scene.add_child(small_fx)
	small_fx.global_position = global_position


func _on_body_entered(body: Node2D) -> void:
	if body.owner is Inkwell and not can_hit_enemy:
		return
	var hit_vector: Vector2 = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	add_small_fx()
	duration_timer.start()
	if body.owner is Inkwell:
		var inkwell: Inkwell = body.owner as Inkwell
		if inkwell.ink_color_name == ink_color_name:
			inkwell.fill()
			queue_free()
	elif body.owner is Player:
		can_hit_enemy = true
		hit_sound.play()


func _on_duration_timer_timeout() -> void:
	var big_fx: Node2D = big_fx_scene.instantiate()
	big_fx.ink_color_name = ink_color_name
	get_tree().current_scene.add_child(big_fx)
	big_fx.global_position = global_position
	queue_free()
