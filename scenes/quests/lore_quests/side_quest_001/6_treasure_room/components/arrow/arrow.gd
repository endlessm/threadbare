extends CharacterBody2D


@export var speed = 300.0

var spawn_pos: Vector2

func _ready() -> void:
	global_position = spawn_pos


func _physics_process(delta: float) -> void:
	velocity = Vector2(0, speed)
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	queue_free()
	if body.is_in_group("player"):
		body.defeat()


func _on_duration_timer_timeout() -> void:
	queue_free()
