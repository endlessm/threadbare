# eco_floater_guard.gd
extends "res://scenes/quests/story_quests/estation _echo_9/2_containment_passages/containment_passages_enemies/eco_base.gd"

@export var speed: float = 50.0 # Lento
var direction: int = 1
var distance_travelled: float = 0.0
@export var patrol_distance: float = 200.0

func _physics_process(delta: float) -> void:
	velocity.x = speed * direction
	move_and_slide()

	distance_travelled += speed * delta

	if distance_travelled >= patrol_distance:
		direction *= -1
		distance_travelled = 0.0
