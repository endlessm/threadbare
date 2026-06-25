extends Control

@export var dialogo_recurso: DialogueResource
var balloon_scene: PackedScene = preload("res://scenes/ui_elements/dialogue/balloon.tscn")
var tablero: Array[int] = [
	1, 2, 3,
	4, 5, 6,
	7, 8, 0
]

@onready var grid: GridContainer = $GridContainer
@onready var musica_fondo: AudioStreamPlayer2D = $MusicaFondo

var juego_activo: bool = false
var dialogo_inicial_terminado: bool = false

# Ruta del archivo donde se guarda el estado del acertijo
const RUTA_ESTADO_ACERTIJO: String = "user://acertijo_resuelto.save"


func _ready() -> void:
	randomize()
	# Mostrar diálogo inicial (creando un balloon nuevo)
	_mostrar_dialogo("inicio")
	# Conectar botones
	for i in range(9):
		grid.get_child(i).pressed.connect(func() -> void: mover_ficha(i))
	mezclar_tablero()
	actualizar_tablero()


func _mostrar_dialogo(titulo: String) -> void:
	if not dialogo_recurso:
		print("Error: No hay recurso de diálogo asignado")
		_iniciar_juego()
		return
	var balloon: Node = balloon_scene.instantiate()
	add_child(balloon)
	balloon.start(dialogo_recurso, titulo)
	# Esperar a que el balloon termine
	await balloon.tree_exited
	# Cuando termina el diálogo, decidir qué hacer según el título
	if titulo == "inicio":
		_iniciar_juego()
	elif titulo == "ganaste":
		_victoria()


func _iniciar_juego() -> void:
	juego_activo = true
	if musica_fondo and musica_fondo.playing:
		musica_fondo.stop()
	actualizar_tablero()   # Habilita los botones
	print("Puzzle activo - puedes mover las fichas")


func _victoria() -> void:
	print("¡Puzzle completado! ")
	_guardar_acertijo_resuelto()
	# instanciar puerta, cambiar de escena
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.1.tscn")


func actualizar_tablero() -> void:
	for i in range(9):
		var boton: Button = grid.get_child(i)
		if tablero[i] == 0:
			boton.text = ""
			boton.disabled = true
		else:
			boton.text = str(tablero[i])
			boton.disabled = not juego_activo


func mover_ficha(indice: int) -> void:
	if not juego_activo:
		return
	var vacio: int = tablero.find(0)
	if not es_vecino(indice, vacio):
		return
	var temp: int = tablero[indice]
	tablero[indice] = tablero[vacio]
	tablero[vacio] = temp
	actualizar_tablero()
	if puzzle_resuelto():
		juego_activo = false
		actualizar_tablero()
		# Punto exacto de victoria: se guarda el estado antes de mostrar el diálogo
		_guardar_acertijo_resuelto()
		_mostrar_dialogo("ganaste")   # Muestra el diálogo de victoria (instancia nueva)


func es_vecino(a: int, b: int) -> bool:
	var fila_a: int = int(a / 3)
	var col_a: int = a % 3
	var fila_b: int = int(b / 3)
	var col_b: int = b % 3
	return abs(fila_a - fila_b) + abs(col_a - col_b) == 1


func puzzle_resuelto() -> bool:
	return tablero == [1, 2, 3, 4, 5, 6, 7, 8, 0]


func mezclar_tablero(pasos: int = 100) -> void:
	for i in range(pasos):
		var vacio: int = tablero.find(0)
		var movimientos: Array[int] = []
		for j in range(9):
			if es_vecino(j, vacio):
				movimientos.append(j)
		var mover: int = movimientos.pick_random()
		var temp: int = tablero[mover]
		tablero[mover] = tablero[vacio]
		tablero[vacio] = temp


func _guardar_acertijo_resuelto() -> void:
	var archivo: FileAccess = FileAccess.open(RUTA_ESTADO_ACERTIJO, FileAccess.WRITE)
	if archivo:
		archivo.store_string("true")
		archivo.close()
