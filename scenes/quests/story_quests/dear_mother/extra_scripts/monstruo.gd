extends AnimatedSprite2D

@export_file("*.tscn") var ruta_madre: String

# Esta es la función que llamaremos desde tu cinemática
func transformar_en_madre() -> void:
	var tween: Tween = create_tween()
	
	var origen_x: float = position.x
	
	for i in range(12):
		var desplazamiento = 8 if i % 2 == 0 else -8
		tween.tween_property(self, "position:x", origen_x + desplazamiento, 0.05)
		
	tween.tween_property(self, "position:x", origen_x, 0.05)
	
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0), 1.0)
	
	tween.tween_callback(invocar_madre)

func invocar_madre() -> void:
	if ruta_madre != "":
		var escena_madre = load(ruta_madre)
		if escena_madre:
			var nueva_madre = escena_madre.instantiate()
			

			nueva_madre.global_position = global_position + Vector2(0, 125)
			
			if nueva_madre.has_node("AnimatedSprite2D"):
				var sprite_madre: AnimatedSprite2D = nueva_madre.get_node("AnimatedSprite2D")
				sprite_madre.flip_h = true
			
			get_parent().add_child(nueva_madre)
	else:
		print("¡Error! Falta asignar la ruta de la madre en el Inspector.")
		
	queue_free()
