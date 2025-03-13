extends RigidBody2D

@export var initial_impulse: Vector2

func _ready() -> void:
	apply_impulse(initial_impulse)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	if body.owner is Enemy:
		body.owner.got_hit(global_position, hit_vector)
