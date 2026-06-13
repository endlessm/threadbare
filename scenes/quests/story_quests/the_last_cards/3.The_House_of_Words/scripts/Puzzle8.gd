extends Control

@export var dialogo_recurso: DialogueResource
var balloon_scene = preload("res://scenes/ui_elements/dialogue/balloon.tscn")  # Ajusta la ruta

var tablero = [
	1, 2, 3,
	4, 5, 6,
	7, 8, 0
]

@onready var grid = $GridContainer

var juego_activo = false
var dialogo_inicial_terminado = false


func _ready():
	randomize()
	
	# Mostrar diálogo inicial (creando un balloon nuevo)
	_mostrar_dialogo("inicio")
	
	# Conectar botones
	for i in range(9):
		grid.get_child(i).pressed.connect(func(): mover_ficha(i))
	
	mezclar_tablero()
	actualizar_tablero()


func _mostrar_dialogo(titulo: String):
	if not dialogo_recurso:
		print("Error: No hay recurso de diálogo asignado")
		_iniciar_juego()
		return
	
	var balloon = balloon_scene.instantiate()
	add_child(balloon)
	balloon.start(dialogo_recurso, titulo)
	# Esperar a que el balloon termine (se destruye solo)
	await balloon.tree_exited
	
	# Cuando termina el diálogo, decidir qué hacer según el título
	if titulo == "inicio":
		_iniciar_juego()
	elif titulo == "ganaste":
		_victoria()


func _iniciar_juego():
	juego_activo = true
	actualizar_tablero()   # Habilita los botones
	print("Puzzle activo - puedes mover las fichas")


func _victoria():
	print("¡Puzzle completado! Aquí puedes agregar la puerta o cambiar de escena")
	# Ejemplo: instanciar puerta, cambiar de escena, etc.
	# get_tree().change_scene_to_file("ruta_siguiente_escena.tscn")


func actualizar_tablero():
	for i in range(9):
		var boton = grid.get_child(i)
		if tablero[i] == 0:
			boton.text = ""
			boton.disabled = true
		else:
			boton.text = str(tablero[i])
			boton.disabled = not juego_activo


func mover_ficha(indice):
	if not juego_activo:
		return
	
	var vacio = tablero.find(0)
	if not es_vecino(indice, vacio):
		return
	
	var temp = tablero[indice]
	tablero[indice] = tablero[vacio]
	tablero[vacio] = temp
	
	actualizar_tablero()
	
	if puzzle_resuelto():
		juego_activo = false
		actualizar_tablero()
		_mostrar_dialogo("ganaste")   # Muestra el diálogo de victoria (instancia nueva)


func es_vecino(a, b):
	var fila_a = int(a / 3)
	var col_a = a % 3
	var fila_b = int(b / 3)
	var col_b = b % 3
	return abs(fila_a - fila_b) + abs(col_a - col_b) == 1


func puzzle_resuelto():
	return tablero == [1, 2, 3, 4, 5, 6, 7, 8, 0]


func mezclar_tablero(pasos := 100):
	for i in range(pasos):
		var vacio = tablero.find(0)
		var movimientos = []
		for j in range(9):
			if es_vecino(j, vacio):
				movimientos.append(j)
		var mover = movimientos.pick_random()
		var temp = tablero[mover]
		tablero[mover] = tablero[vacio]
		tablero[vacio] = temp
