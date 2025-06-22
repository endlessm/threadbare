extends Area2D
@export var velocidad: float = 200.0
@export var direccion: Vector2 = Vector2.LEFT

func _process(delta):
	position += direccion.normalized() * velocidad * delta

func _on_area_entered(area):
	if area.name == "Espada":
		queue_free()
