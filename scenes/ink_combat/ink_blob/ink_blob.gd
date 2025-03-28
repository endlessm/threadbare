class_name InkBlob
extends RigidBody2D

enum InkColorNames {
	CYAN = 0,
	MAGENTA = 1,
	YELLOW = 2,
	BLACK = 3,
}

const ENEMY_HITBOX_LAYER: int = 128

const INK_COLORS: Dictionary = {
	InkColorNames.CYAN: Color(0., 1., 1.),
	InkColorNames.MAGENTA: Color(1., 0., 1.),
	InkColorNames.YELLOW: Color(1., 1., 0.),
	InkColorNames.BLACK: Color(0.2, 0.2, 0.2),
}

const SPEED: float = 30.0

@export var direction: Vector2 = Vector2(0, -60)
@export var can_hit_enemy: bool = false:
	set = _set_can_hit_enemy
@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

@onready var visible_things: Node2D = %VisibleThings
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D


func _set_can_hit_enemy(new_can_hit_enemy: bool) -> void:
	can_hit_enemy = new_can_hit_enemy
	set_collision_mask_value(ENEMY_HITBOX_LAYER, can_hit_enemy)
	animation_player.speed_scale = 2 if can_hit_enemy else 1
	gpu_particles_2d.amount_ratio = 1. if can_hit_enemy else .1


func _ready() -> void:
	var color: Color = INK_COLORS[ink_color_name]
	visible_things.modulate = color
	var impulse: Vector2 = direction.normalized() * SPEED
	apply_impulse(impulse)


func _process(_delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()


func _on_body_entered(body: Node2D) -> void:
	var hit_vector: Vector2 = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	if body.owner is Inkwell:
		var inkwell: Inkwell = body.owner as Inkwell
		if inkwell.ink_color_name == ink_color_name:
			inkwell.fill()
			queue_free()
		inkwell.got_hit(global_position, hit_vector, ink_color_name)
	elif body.owner is FightingPlayer:
		can_hit_enemy = true
