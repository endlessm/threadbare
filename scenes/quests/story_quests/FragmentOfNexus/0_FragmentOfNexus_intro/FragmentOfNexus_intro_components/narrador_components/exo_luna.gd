extends ParallaxLayer

@onready var asteroide = $"Prop-planet-small"
@export var velocidad_rotacion: float = 2.0

func _process(delta):
	asteroide.rotation_degrees += velocidad_rotacion * delta
