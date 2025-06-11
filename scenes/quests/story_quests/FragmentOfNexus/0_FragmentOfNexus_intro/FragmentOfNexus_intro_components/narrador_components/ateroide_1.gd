extends ParallaxLayer

@onready var asteroide = $"Asteroid-2"
@export var velocidad_rotacion: float = 30.0

func _process(delta):
	asteroide.rotation_degrees += velocidad_rotacion * delta
