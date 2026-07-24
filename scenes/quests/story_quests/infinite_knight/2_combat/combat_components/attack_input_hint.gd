extends TextureRect

func _process(_delta: float) -> void:
	# Oscurece el icono si se mantiene presionado el ataque
	if Input.is_action_pressed("throw"):
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE
