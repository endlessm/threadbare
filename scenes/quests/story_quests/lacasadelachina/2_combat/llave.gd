extends Area2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	print("Mi padre es: ", get_parent().name)

func _on_body_entered(body):
	if body is Player:
		get_node("/root/LacasadelachinaCombat").llave_recogida_por_jugador()
