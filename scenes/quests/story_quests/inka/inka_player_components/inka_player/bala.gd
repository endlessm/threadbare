extends StaticBody2D

@export var speed := 300
var direction: Vector2 = Vector2.RIGHT

func _process(delta: float) -> void:
	position += direction * speed * delta
