extends Sprite2D

@export var rotation_speed := 10.0  # Grados por segundo

func _process(delta):
	rotation += deg_to_rad(rotation_speed * delta)
