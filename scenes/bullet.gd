extends RigidBody2D

func _ready() -> void:
	var impulse = Vector2(0, -100).rotated(randf_range(-PI/16, PI/16))
	apply_impulse(impulse)


func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	if body.owner is Enemy:
		body.owner.got_hit(global_position, hit_vector)
