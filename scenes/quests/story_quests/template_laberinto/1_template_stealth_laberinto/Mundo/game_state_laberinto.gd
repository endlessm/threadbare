extends Node

# Posición del jugador
var player_position: Vector2 = Vector2.ZERO

# Número de llaves recogidas
var llaves: int = 0

# Lista de cofres, puertas, etc. que han sido abiertos
var abiertos: Array = []

# Marca si una puerta fue forzada con ganzúa
var puerta_ganzua_forzada: bool = false

# Puedes agregar más variables globales según tu juego

# Función para reiniciar el juego
func reset():
	llaves = 0
	puerta_ganzua_forzada = false
	player_position = Vector2.ZERO
	abiertos.clear()  # Limpia la lista de cofres o puertas abiertas

	# Aquí puedes reiniciar otras variables globales si tienes
	# Por ejemplo: vidas, objetos en el inventario, enemigos muertos, etc.

	# Si tienes más sistemas como inventario, enemigos o progreso, reinícialos aquí también
