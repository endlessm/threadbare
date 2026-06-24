extends Node2D
signal pattern_finished

@export var projectile_scene: PackedScene

@export var centro_area: Vector2 = Vector2(500, 300)
@export var rango_x: float = 300.0
@export var rango_y: float = 200.0

@export var max_tandas: int = 3
@export var cantidad_por_tanda: int = 10
@export var tiempo_espera_lanzamiento: float = 1.0
@export var tiempo_entre_proyectiles: float = 0.3
@export var tiempo_entre_tandas: float = 1.5

@export var velocidad: float = 200.0
@export var daño: int = 1
@export var jugador: Node2D

var activo: bool = false
var proyectiles_activos_tanda: int = 0


func start_pattern() -> void:
	if activo:
		return

	activo = true
	loop_tandas()


func stop_pattern() -> void:
	activo = false


func loop_tandas() -> void:
	for tanda in max_tandas:
		if not activo:
			break
			
		var proyectiles_creados = crear_tanda_estatica()
		
		await get_tree().create_timer(tiempo_espera_lanzamiento).timeout
		
		await lanzar_proyectiles_uno_a_uno(proyectiles_creados)
		
		await get_tree().create_timer(tiempo_entre_tandas).timeout

	if activo:
		stop_pattern()
		emit_signal("pattern_finished")


func crear_tanda_estatica() -> Array:
	var lista_proyectiles: Array = []
	proyectiles_activos_tanda = cantidad_por_tanda

	for i in cantidad_por_tanda:
		var pos = crear_posicion_borde()
		var p = spawn_projectile_quieto(pos)
		if p:
			lista_proyectiles.append(p)
			
	return lista_proyectiles


func lanzar_proyectiles_uno_a_uno(lista_proyectiles: Array) -> void:
	for p in lista_proyectiles:
		if not activo:
			return
			
		if is_instance_valid(p):
			var dir_hacia_jugador = Vector2.DOWN
			if jugador:
				dir_hacia_jugador = (jugador.global_position - p.global_position).normalized()
			
			p.activar_movimiento(dir_hacia_jugador, velocidad, daño)
			
			await get_tree().create_timer(tiempo_entre_proyectiles).timeout
			
	while proyectiles_activos_tanda > 0 and activo:
		await get_tree().process_frame


func spawn_projectile_quieto(posicion: Vector2) -> Node:
	if projectile_scene == null:
		return null

	var p = projectile_scene.instantiate()
	p.setup(posicion)
	
	p.tree_exited.connect(func(): proyectiles_activos_tanda -= 1)
	
	add_child(p)
	return p


func crear_posicion_borde() -> Vector2:
	var lado = randi_range(0, 3)
	match lado:
		0:
			return Vector2(randf_range(centro_area.x - rango_x, centro_area.x + rango_x), centro_area.y - rango_y)
		1:
			return Vector2(randf_range(centro_area.x - rango_x, centro_area.x + rango_x), centro_area.y + rango_y)
		2:
			return Vector2(centro_area.x - rango_x, randf_range(centro_area.y - rango_y, centro_area.y + rango_y))
		3:
			return Vector2(centro_area.x + rango_x, randf_range(centro_area.y - rango_y, centro_area.y + rango_y))
	return Vector2.ZERO
	
