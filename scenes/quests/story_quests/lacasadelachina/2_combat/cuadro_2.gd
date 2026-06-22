extends Area2D

@export var mi_indice: int = 0

var en_cooldown = false

var cuadros: Array = [
	Vector2(599, 150),
	Vector2(479, 450),
	Vector2(487, 150),
	Vector2(-81, 100),
	Vector2(1063, 450),
]

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player and not en_cooldown:
		en_cooldown = true
		var opciones = cuadros.duplicate()
		opciones.remove_at(mi_indice)
		var destino = opciones[randi() % opciones.size()]
		body.teleport_to(destino)
		await get_tree().create_timer(1.5).timeout
		en_cooldown = false
