extends Node2D
signal pattern_finished


@export var projectile_scene: PackedScene

@export var centro_area: Vector2 = Vector2(500, 300)
@export var rango_x: float = 300.0
@export var rango_y: float = 200.0

@export var max_tandas: int = 3
@export var cantidad_por_tanda: int = 10
@export var tiempo_entre_creacion: float = 0.15 # <- NUEVA: Tiempo de espera entre la aparición de cada proyectil quieto
@export var tiempo_espera_lanzamiento: float = 1.0
@export var tiempo_entre_proyectiles: float = 0.3
@export var tiempo_entre_tandas: float = 1.5

@export var velocidad: float = 200.0
@export var daño: int = 1
@export var jugador: Node2D

var activo: bool = false


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
			
		# 1. Creamos la tanda proyectil por proyectil esperando el tiempo asignado
		var proyectiles_creados = await crear_tanda_estatica_progresiva()
		
		# 2. Espera intermedia antes de empezar a disparar la tanda completa
		await get_tree().create_timer(tiempo_espera_lanzamiento).timeout
		
		# 3. Lanzamos los proyectiles en el mismo orden de creación
		await lanzar_proyectiles_uno_a_uno(proyectiles_creados)
		
		# Si es la última tanda, terminamos inmediatamente sin esperar el tiempo de descanso
		if tanda < max_tandas - 1:
			await get_tree().create_timer(tiempo_entre_tandas).timeout

	if activo:
		stop_pattern()
		emit_signal("pattern_finished")


func crear_tanda_estatica_progresiva() -> Array:
	var lista_proyectiles: Array = []

	for i in cantidad_por_tanda:
		if not activo:
			break
			
		var pos = crear_posicion_borde()
		var p = spawn_projectile_quieto(pos)
		if p:
			lista_proyectiles.append(p)
			
		# Esperamos antes de crear el siguiente proyectil de la tanda, excepto para el último
		if i < cantidad_por_tanda - 1:
			await get_tree().create_timer(tiempo_entre_creacion).timeout
			
	return lista_proyectiles


func lanzar_proyectiles_uno_a_uno(lista_proyectiles: Array) -> void:
	var total = lista_proyectiles.size()
	
	for i in total:
		if not activo:
			return
			
		var p = lista_proyectiles[i] # Mantiene estrictamente el orden del Array
			
		if is_instance_valid(p):
			var dir_hacia_jugador = Vector2.DOWN
			if jugador:
				dir_hacia_jugador = (jugador.global_position - p.global_position).normalized()
			
			p.activar_movimiento(dir_hacia_jugador, velocidad, daño)
			
			# Solo espera si NO es el último proyectil de esta tanda
			if i < total - 1:
				await get_tree().create_timer(tiempo_entre_proyectiles).timeout


func spawn_projectile_quieto(posicion: Vector2) -> Node:
	if projectile_scene == null:
		return null

	var p = projectile_scene.instantiate()
	p.setup(posicion)
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
