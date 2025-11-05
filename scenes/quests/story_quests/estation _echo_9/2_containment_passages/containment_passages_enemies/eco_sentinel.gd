# eco_sentinel.gd
extends "res://scenes/quests/story_quests/estation _echo_9/2_containment_passages/containment_passages_enemies/eco_base.gd"

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	rotate(deg_to_rad(90))
