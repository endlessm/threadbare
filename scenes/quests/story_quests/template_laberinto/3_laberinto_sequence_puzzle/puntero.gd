extends Node2D
func _process(delta: float) -> void:
	var objetivo = get_global_mouse_position()
	position = position.lerp(objetivo, 10 * delta)
