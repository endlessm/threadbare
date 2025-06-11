extends ParallaxLayer

@onready var asteroide = $"Asteroid-3"
@export var velocidad_rotacion: float = 10.0

func _process(delta):
	asteroide.rotation_degrees += velocidad_rotacion * delta
