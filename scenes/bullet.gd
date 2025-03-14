extends RigidBody2D

@export var initial_impulse: Vector2
@onready var sprite_2d: Sprite2D = %Sprite2D

func _ready() -> void:
	sprite_2d.frame = randi() % 4
	apply_impulse(initial_impulse)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector.normalized() * 250)
	if body.owner is Enemy:
		body.owner.got_hit(global_position, hit_vector)
