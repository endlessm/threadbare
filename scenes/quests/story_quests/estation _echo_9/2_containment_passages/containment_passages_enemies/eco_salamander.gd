# eco_salamander.gd
extends "res://scenes/quests/story_quests/estation _echo_9/2_containment_passages/containment_passages_enemies/eco_base.gd"

@export var speed: float = 150.0 # Rápido

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	var random_direction: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	velocity = random_direction * speed
