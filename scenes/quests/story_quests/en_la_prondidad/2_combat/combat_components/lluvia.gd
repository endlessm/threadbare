extends Node2D

signal pattern_finished

@export var projectile_scene: PackedScene
@export var spawn_y: float = 100.0

@export var ancho_inicio: float = 0.0
@export var ancho_fin: float = 500.0
@export var espacio: float = 40.0

@export var offset_x: float = 15.0
@export var tiempo_entre_tandas: float = 1.0
@export var duracion: float = 5.0

@export var velocidad: float = 200.0
@export var daño: int = 1

var activo: bool = false
var usar_offset: bool = false

func start_pattern() -> void:
	if activo:
		return

	activo = true
	usar_offset = false

	loop_tandas()
	control_duracion()

func stop_pattern() -> void:
	activo = false

func loop_tandas() -> void:
	while activo:
		crear_tanda()
		await get_tree().create_timer(tiempo_entre_tandas).timeout

func control_duracion() -> void:
	await get_tree().create_timer(duracion).timeout
	emit_signal("pattern_finished")

func crear_tanda() -> void:
	var offset := 0.0

	if usar_offset:
		offset = offset_x

	var x := ancho_inicio + offset

	while x <= ancho_fin:
		spawn_projectile(x)
		x += espacio

	usar_offset = not usar_offset

func spawn_projectile(x: float) -> void:
	if projectile_scene == null:
		return

	var p = projectile_scene.instantiate()

	var posicion = Vector2(x, spawn_y)
	
	p.setup(posicion)
	
	add_child(p)
	
	p.activar_movimiento(Vector2.DOWN, velocidad, daño)
