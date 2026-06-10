extends AnimatedSprite2D

var velocidad := 20.0
var caminando := true
var destino_x := -400

func _ready() -> void:
	position = Vector2(-650, 470)
	play("walk")

func _process(delta: float) -> void:
	if caminando:
		position.x += velocidad * delta

		if position.x >= destino_x:
			position.x = destino_x
			caminando = false

func caminar_hasta(x: float):
	destino_x = x
	caminando = true
	
