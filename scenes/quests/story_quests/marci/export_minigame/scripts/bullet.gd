extends Area2D

@export var speed := 400.0
var direction := Vector2.ZERO

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	# Usamos global_position en lugar de position
	global_position += direction * speed * delta

	# Si la bala sale muy lejos del jugador, se elimina
	if global_position.length() > 10000:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(1)
		queue_free()
