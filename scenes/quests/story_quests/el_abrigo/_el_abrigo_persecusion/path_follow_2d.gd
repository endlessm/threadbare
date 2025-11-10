extends PathFollow2D

var speed = 0.041

func _process(delta: float) -> void:
	progress_ratio += delta*speed
