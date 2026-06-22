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
		# ✅ Si el árbol ya no existe, eliminamos la bala silenciosamente
		if not is_inside_tree():
			return
		global_position += direccion * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		return
	if body is Guard:
		body.queue_free()
	queue_free()

func _exit_tree():
	# ✅ Cuando la escena cambia, esto se llama automáticamente
	pass
