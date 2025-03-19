class_name Bullet
extends RigidBody2D

const ENEMY_HITBOX_LAYER = 9
const SPEED = 30.

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0
@export var direction: Vector2 = Vector2(0, -60)
@export var can_hit_enemy: bool = false:
		set = _set_can_hit_enemy

@onready var visible_things: Node2D = %VisibleThings
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D

func _set_can_hit_enemy(new_can_hit_enemy) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(ENEMY_HITBOX_LAYER, can_hit_enemy)
	animation_player.speed_scale = 2 if can_hit_enemy else 1
	gpu_particles_2d.amount_ratio = 1. if can_hit_enemy else .1

func _ready() -> void:
	var color: Color = Globals.INK_COLORS[ink_color_name]
	visible_things.modulate = color
	var impulse = direction.normalized() * SPEED
	apply_impulse(impulse)

func _process(delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	

func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	# Feels better without:
	apply_impulse(hit_vector) #.normalized() * SPEED
	if body.owner is Inkwell:
		var inkwell = body.owner as Inkwell
		if inkwell.ink_color_name == ink_color_name:
			inkwell.fill()
			queue_free()
		inkwell.got_hit(global_position, hit_vector, ink_color_name)
	elif body.owner is Player:
		can_hit_enemy = true
