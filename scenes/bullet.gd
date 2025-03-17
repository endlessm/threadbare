extends RigidBody2D

@onready var visible_things: Node2D = %VisibleThings


func _ready() -> void:
	var impulse = Vector2(0, -60).rotated(randf_range(-PI/16, PI/16))
	apply_impulse(impulse)

func _process(delta: float) -> void:
	visible_things.rotation = linear_velocity.angle()
	

func _on_body_entered(body: Node2D) -> void:
	var hit_vector = global_position - body.global_position
	linear_velocity = Vector2.ZERO
	apply_impulse(hit_vector)
	if body.owner is Enemy:
		body.owner.got_hit(global_position, hit_vector)
