class_name Bullet
extends RigidBody2D

@export_enum("Cyan", "Magenta", "Yellow", "Black") var ink_color_name: int = 0

const SPEED = 60.

@export var direction: Vector2 = Vector2(0, -60)
@onready var visible_things: Node2D = %VisibleThings


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
	apply_impulse(hit_vector.normalized() * SPEED)
	if body.owner is Inkwell:
		var inkwell = body.owner as Inkwell
		if inkwell.ink_color_name == ink_color_name:
			inkwell.fill()
			queue_free()
		inkwell.got_hit(global_position, hit_vector, ink_color_name)
