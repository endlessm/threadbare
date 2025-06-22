extends Area2D

@export var velocidad: float = 150.0
@export var direccion: Vector2 = Vector2.DOWN  # Movimiento hacia abajo

func _process(delta):
	position += direccion.normalized() * velocidad * delta


func _on_Flecha_area_entered(area: Area2D) -> void:
	if area.name == "HitBox" and area.monitoring:
		print("¡Flecha golpeada!")
		queue_free()
