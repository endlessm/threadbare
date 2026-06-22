extends Node2D

var llave_recogida = false
var timer_llave: Timer

func _ready() -> void:
	timer_llave = Timer.new()
	add_child(timer_llave)
	timer_llave.wait_time = 2
	timer_llave.autostart = false
	timer_llave.timeout.connect(_mover_llave)
	# _mover_llave()
	# timer_llave.start()

func _mover_llave():
	if llave_recogida:
		return
	
	var llave = get_node_or_null("llave")
	if llave == null:
		return
	
	var tile_size = 64
	var min_x = -6 * tile_size
	var max_x = 13 * tile_size
	var min_y = -4 * tile_size
	var max_y = 12 * tile_size
	
	llave.global_position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

func llave_recogida_por_jugador():
	llave_recogida = true
	get_node_or_null("llave").visible = false
	timer_llave.stop()
	print("¡Llave recogida! Puedes pasar al siguiente nivel")
