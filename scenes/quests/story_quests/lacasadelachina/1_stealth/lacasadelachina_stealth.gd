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
	
	# timer_llave = Timer.new()
	# add_child(timer_llave)
	# timer_llave.wait_time = 5.0
	# timer_llave.autostart = true
	# timer_llave.connect("timeout", Callable(self, "_mover_llave"))
	# _mover_llave()

func _mover_llave():
	pass

func llave_recogida_por_jugador():
	pass

func _on_zonewar_body_entered(body: Node2D) -> void:
	print("Zona tocada por: ", body.name)
	if guardian_bloqueado and body.is_in_group("player"):
		print("¡Jugador detectado! Iniciando minijuego...")
		memory_game.iniciar()

func _on_minijuego_completado() -> void:
	guardian_bloqueado = false
