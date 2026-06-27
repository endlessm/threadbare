extends PathFollow2D

# Cambia este número para ajustar la velocidad.
# Un número más pequeño hará que se mueva más lento.
var velocidad = 0.01

func _process(delta):
	progress_ratio += velocidad * delta
