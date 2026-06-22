extends Area2D

## Tiempo en segundos antes de autodestruirse si no choca con nada
## (evita que los proyectiles se acumulen para siempre si nunca tocan al jugador).
@export var tiempo_vida: float = 5.0

var _direccion: Vector2 = Vector2.RIGHT
var _velocidad: float = 200.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(tiempo_vida).timeout.connect(_autodestruir)


## Llamada por la torreta justo después de instanciar el proyectil,
## para indicarle hacia dónde y a qué velocidad debe moverse.
func lanzar(direccion: Vector2, velocidad: float) -> void:
	_direccion = direccion.normalized()
	_velocidad = velocidad
	rotation = _direccion.angle()


func _physics_process(delta: float) -> void:
	global_position += _direccion * _velocidad * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().reload_current_scene()


func _autodestruir() -> void:
	if is_instance_valid(self):
		queue_free()
