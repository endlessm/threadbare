extends Node

@onready var player = %Player
@onready var boss = %BalderFuturo
@onready var mapa = %Sand

enum Tipo {
	NORTE,
	SUR,
	ESTE,
	OESTE,
	NOR_ESTE,   # Diagonal superior derecha
	NOR_OESTE,   # Diagonal superior izquierda
	SUR_ESTE,   # Diagonal inferior derecha
	SUR_OESTE    # Diagonal inferior izquierda
}

const COORDENADAS: Dictionary = {
	Tipo.NORTE:     Vector2i(0, -1),
	Tipo.SUR:       Vector2i(0, 1),
	Tipo.ESTE:      Vector2i(1, 0),
	Tipo.OESTE:     Vector2i(-1, 0),
	
	Tipo.NOR_ESTE:  Vector2i(1, -1),  # Derecha (1), Arriba (-1)
	Tipo.NOR_OESTE: Vector2i(-1, -1), # Izquierda (-1), Arriba (-1)
	Tipo.SUR_ESTE:  Vector2i(1, 1),   # Derecha (1), Abajo (1)
	Tipo.SUR_OESTE: Vector2i(-1, 1)   # Izquierda (-1), Abajo (1)
}

func _on_damaged(body:Node2D)->void:
	if body is Projectile:
		##POR ALGUNA RAZON, ESTO NO FUNCIONABA BIEN, DETECTABA
		##AUNQUE LA COLISION SEA FALSA
		##UN RATO DESPUES FUNCIONO NORMAL PERO LUEGO SE ME CRASHEO
		## Y YA NO FUNCIONO XDD, ASI QUE LO DEJO ASI
		
		if not body.get_collision_mask_value(8): 
			return 
			
		print("me han pegado (¡Este sí es real!)")

func _ejecutar_ataque() -> void:
	# 1. Conseguimos el nodo de tu mapa (asegúrate de que el nombre coincida)
	
	# 2. Traducimos la posición en píxeles del jugador a coordenadas de casilla (Vector2i)
	var casilla_jugador: Vector2i = mapa.local_to_map(player.global_position)
	
	# 3. Calculamos la casilla objetivo: la misma X del jugador, pero 5 casillas ARRIBA (-5 en Y)
	var casilla_inicial_boss: Vector2i = casilla_jugador + Vector2i(0, -2)
	
	# 4. Definimos los parámetros para el ataque de prueba
	var cantidad_ataques: int = 4              # Disparará 4 veces en total # Se irá desplazando hacia el Norte
	
	print("--- INICIANDO ATAQUE DE PRUEBA ---")
	print("Casilla actual del jugador: ", casilla_jugador)
	print("El Boss aparecerá en la casilla: ", casilla_inicial_boss)
	
	# 5. Llamamos a tu función con la coreografía ajustada
	await _atacar_efecto(cantidad_ataques, casilla_inicial_boss, Tipo.NORTE)
	
	print("--- ATAQUE DE PRUEBA TERMINADO ---")
	

func _atacar_efecto(ataques: int, casilla_a_mover: Vector2i, direccion: Tipo) -> void:
	boss.global_position = mapa.map_to_local(casilla_a_mover)
	
	# 2. Ahora sí, ejecuta su ataque por defecto (Disparo 1)
	boss._on_timeout()
	await boss.animation_player.animation_finished
	
	# 3. Obtenemos la dirección del script global
	var vector_direccion: Vector2i = COORDENADAS[direccion]
	var casilla_actual: Vector2i = casilla_a_mover
	
	# 4. Calculamos cuántos tiros quedan pendientes
	var tiros_restantes: int = ataques - 1
	
	# Si nos quedan tiros por hacer, entramos al bucle
	for a in tiros_restantes:
		# Como ya disparó, primero se mueve una casilla hacia la dirección
		casilla_actual = casilla_actual + vector_direccion
		boss.global_position = mapa.map_to_local(casilla_actual)
		# El jefe hace el siguiente disparo de la ráfaga
		boss.shoot_projectile_at(player)
		# Esperamos el pequeño bache de tiempo antes del siguiente tiro
		await get_tree().create_timer(0.3).timeout

func _pausar()->void:
	boss.timer.stop();

func _reanudar()->void:
	boss.timer.start();	
	
