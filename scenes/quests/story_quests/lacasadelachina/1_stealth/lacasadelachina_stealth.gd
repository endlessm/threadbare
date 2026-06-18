extends Node2D

@onready var guardian    = get_node("EnemyGuards/Guard1-GoingBackAndForth")
@onready var memory_game = get_node("ScreenOverlay/Memorygame")
var guardian_bloqueado := true

var llave_recogida = false
var timer_llave: Timer

func _ready() -> void:
	memory_game.minijuego_completado.connect(_on_minijuego_completado)
	guardian.set_process(false)
	guardian.set_physics_process(false)
	
	# Timer de la llave
	timer_llave = Timer.new()
	add_child(timer_llave)
	timer_llave.wait_time = 5.0
	timer_llave.autostart = true
	timer_llave.connect("timeout", Callable(self, "_mover_llave"))
	_mover_llave()

func _mover_llave():
	if llave_recogida:
		return
	
	var tile_size = 16  # Cambia si tus tiles son de otro tamaño
	var min_x = -6 * tile_size
	var max_x = 13 * tile_size
	var min_y = -4 * tile_size
	var max_y = 12 * tile_size
	
	var pos_x = randf_range(min_x, max_x)
	var pos_y = randf_range(min_y, max_y)
	
	$llave.global_position = Vector2(pos_x, pos_y)

func llave_recogida_por_jugador():
	llave_recogida = true
	$llave.visible = false
	timer_llave.stop()
	print("¡llave recogida! Puedes pasar al siguiente nivel")

func _on_zonewar_body_entered(body: Node2D) -> void:
	print("Zona tocada por: ", body.name)
	if guardian_bloqueado and body.is_in_group("player"):
		print("¡Jugador detectado! Iniciando minijuego...")
		memory_game.iniciar()

func _on_minijuego_completado() -> void:
	guardian_bloqueado = false
