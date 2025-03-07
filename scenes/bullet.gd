extends RigidBody2D

func _ready() -> void:
	var impulse = Vector2(-100, 0).rotated(randf_range(-PI/8, PI/8))
	apply_impulse(impulse)


func _on_body_entered(body: Node2D) -> void:
	# FIXME if body is the shield
	var impulse = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(impulse)
