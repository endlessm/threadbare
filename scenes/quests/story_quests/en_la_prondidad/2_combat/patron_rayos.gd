extends Node2D

signal pattern_finished

@export var laser_scene: PackedScene
@export var eventos: Array[LaserEvent] = []

@export var x_izquierda: float
@export var x_derecha: float
@export var y_arriba: float
@export var y_abajo: float

var active: bool = false


func start_pattern() -> void:
	if active:
		return
	
	active = true
	run()


func stop_pattern() -> void:
	active = false


func run() -> void:
	var tiempo_actual = 0.0
	
	for e in eventos:
		if not active:
			break
		
		var espera = e.tiempo - tiempo_actual
		tiempo_actual = e.tiempo
		
		if espera > 0:
			await get_tree().create_timer(espera).timeout
		
		spawn_laser(e)
	
	pattern_finished.emit()


func spawn_laser(e: LaserEvent) -> void:
	var pos = Vector2.ZERO
	var dir = Vector2.RIGHT
	
	match e.lado:
		"izq":
			pos.x = x_izquierda
			pos.y = e.posicion
			dir = Vector2.RIGHT
		
		"der":
			pos.x = x_derecha
			pos.y = e.posicion
			dir = Vector2.LEFT
		
		"arr":
			pos.y = y_arriba
			pos.x = e.posicion
			dir = Vector2.DOWN
		
		"aba":
			pos.y = y_abajo
			pos.x = e.posicion
			dir = Vector2.UP
	
	var laser = laser_scene.instantiate()
	laser.setup(pos, dir, 1.0, 0.5)
	
	add_child(laser)
