extends Area2D

var en_cooldown = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player and not en_cooldown:
		en_cooldown = true
		var cuadros = [
			Vector2(599, 150),   # fuera del cuadro, arriba
			Vector2(479, 450),
			Vector2(487, 150),
			Vector2(-81, 100),
			Vector2(1063, 450),
		]
		var destino = cuadros[randi() % cuadros.size()]
		body.teleport_to(destino)
		await get_tree().create_timer(1.5).timeout
		en_cooldown = false
