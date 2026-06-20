extends Area2D

var velocidad = 300
var direccion: Vector2 = Vector2.RIGHT
var iniciado: bool = false

func iniciar(pos: Vector2, dir: Vector2) -> void:
	direccion = dir
	global_position = pos
	rotation = dir.angle()
	iniciado = true

func _ready():
	add_to_group("projectiles")
	monitoring = false
	await get_tree().process_frame
	await get_tree().process_frame
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta):
	if iniciado:
		global_position += direccion * velocidad * delta

func _on_body_entered(body):
	if body.name == "Player":
		return
	queue_free()
