extends PathFollow2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var speed: float = 90.0  # píxeles por segundo

var direction := 1  # 1 = adelante, -1 = atrás
var path_length := 0.0

func _ready() -> void:
	loop = false  # lo controlamos manualmente
	sprite.play("idle")

	# Obtener la longitud del camino desde el Path2D
	var path := get_parent() as Path2D
	if path and path.curve:
		path_length = path.curve.get_baked_length()

func _process(delta: float) -> void:
	progress += speed * delta * direction

	# Transición suave al invertir dirección
	if progress >= path_length:
		progress = path_length
		direction = -1
	elif progress <= 0:
		progress = 0
		direction = 1
