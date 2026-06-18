extends Node

@onready var player = %Player
@onready var boss = %BalderFuturo
@onready var mapa = %Sand

@onready var pos_inicial_disparos=%EnemigosDisparos.global_position
@onready var pos_inicial_targets = %PlayerTargets.global_position
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
		
func ataque_barrido_prueba()->void:
	ataque_direcciones(Tipo.NOR_OESTE)

func ataque_direcciones(direccion:Tipo)->void:
	var direccion_enemigos = direccion_patron(direccion)
	
	##Seran 4 posiciones de enemigos para simular 5 disparos (4 + el boss)
	##los enemigos se generaran alado del jefe y si la direccion es una diagonal
	##como diagonal
	var posicion_boss = mapa.local_to_map(mapa.to_local(boss.global_position))
	var posicion_player = mapa.local_to_map(mapa.to_local(player.global_position))
	
	var posiciones_disparos = patron_posiciones(posicion_boss,direccion_enemigos)
	var posiciones_target = patron_posiciones(posicion_player,direccion_enemigos)
	
	var targets = %PlayerTargets.get_children();
	
	var disparos = %EnemigosDisparos.get_children();
	
	##si o si deben ser 4 disparos y 4 targets, sino crashea xd
	colocar_nodos(posiciones_disparos,disparos)
	colocar_nodos(posiciones_target,targets)
	
	##una vez colocado disparamos
	var i = 0
	for d in disparos:
		d.shoot_projectile_at(targets[i])
		i = i+1
		
func colocar_nodos(posiciones:Array[Vector2i],nodos:Array[Node])->void:
	var i = 0
	for n:Node2D in nodos:
		var pos = mapa.to_global(mapa.map_to_local(posiciones[i]))
		n.global_position = pos
		i = i+1

func reset_nodos(nodos:Array[Node], posicion_inicial:Vector2i):
	for n:Node2D in nodos:
		n.global_position = posicion_inicial
		
func direccion_patron(direccion:Tipo)->Vector2i:
	var direccion_mover = Vector2i(0,0);
	match direccion:
		Tipo.NORTE, Tipo.SUR:
			direccion_mover = Vector2i(1, 0)
		Tipo.ESTE, Tipo.OESTE:
			direccion_mover = Vector2i(0, 1)
		Tipo.NOR_ESTE, Tipo.SUR_OESTE:
			direccion_mover = Vector2i(1, 1)
		Tipo.NOR_OESTE, Tipo.SUR_ESTE:
			direccion_mover = Vector2i(-1, 1)
	return direccion_mover		

func patron_posiciones(posicion,direccion)->Array[Vector2i]:
	##la posicion debe ser usando maptolocal
	var posicion_iterada = posicion
	var posiciones_nuevas : Array[Vector2i] = []
	
	for e in 2:
		posicion_iterada = posicion_iterada+direccion
		posiciones_nuevas.push_front(posicion_iterada)
		
	posicion_iterada = posicion
	direccion = direccion * (-1)
	
	for e in 2:
		posicion_iterada = posicion_iterada+direccion
		posiciones_nuevas.push_front(posicion_iterada)
	
	return posiciones_nuevas

func _pausar()->void:
	boss.timer.stop();

func _reanudar()->void:
	boss.timer.start();	
	
