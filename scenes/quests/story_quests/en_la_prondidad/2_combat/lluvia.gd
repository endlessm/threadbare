extends Node2D

@export var projectile_scene: PackedScene
@export var spawn_y: float = 100.0

@export var ancho_inicio: float = 0.0
@export var ancho_fin: float = 500.0
@export var espacio: float = 40.0

@export var offset_x: float = 15.0
@export var tiempo_entre_tandas: float = 1.0

@export var velocidad: float = 200.0
@export var daño: int = 1

var activo: bool = false
var usar_offset: bool = false

func start_pattern() -> void:
	if activo:
		return

	activo = true
	usar_offset = false
	crear_loop()

func stop_pattern() -> void:
	activo = false

func crear_loop() -> void:
	if not activo:
		return

	crear_tanda()

	await get_tree().create_timer(tiempo_entre_tandas).timeout

	crear_loop()  

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

	p.setup(
		Vector2(x, spawn_y),
		Vector2.DOWN,
		velocidad,
		daño
	)

	add_child(p)
