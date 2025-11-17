extends Sprite2D

var tiempo = 0.1

func _ready():
	modulate = Color(0.3, 0.3, 0.3, 1.0)

func _process(delta):
	tiempo += delta
	
	var brillo = 0.4 + (tiempo * 0.6)
	
	if brillo > 1.2:
		brillo = 1.2
	
	modulate = Color(brillo, brillo * 0.95, brillo * 0.85, 1.0)
