extends TextureRect

func _process(_delta: float) -> void:
	# Oscurece la imagen si mantienes el clic, la vuelve blanca si lo sueltas
	if Input.is_action_pressed("attack"):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE
