extends Area2D

@export var hits_to_win: int = 3
var hits: int = 0

func _on_body_entered(body: Node2D) -> void:
	hits += 1
	if(hits >= hits_to_win):
		set_deferred("monitoring", true)
	pass # Replace with function body.
