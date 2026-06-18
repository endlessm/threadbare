extends ThrowingEnemy


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
@export var mapa:TileMapLayer
@export var player:Player

##LOS DISPAROS Y TARGETS DEBEN TENER EL MISMO TAMAÑO
@export var disparos:Array[Node2D]
@export var targets:Array[Node2D]

var velocidad_actual_projectil:int

func _atacar_efecto(ataques: int, casilla_a_mover: Vector2i, direccion: Tipo, es_barrido:bool) -> void:
	global_position = mapa.map_to_local(casilla_a_mover)
	# 2. Ahora sí, ejecuta su ataque por defecto (Disparo 1)
	_is_attacking = true
	animation_player.play(&"attack")
	await animation_player.animation_finished
	
	if es_barrido:##si queremos que sea ataque barrido le ponemos true
		ataque_barrido(direccion)
			
	# 3. Obtenemos la dirección del script global
	var vector_direccion: Vector2i = COORDENADAS[direccion]
	var casilla_actual: Vector2i = casilla_a_mover
	
	# 4. Calculamos cuántos tiros quedan pendientes
	var tiros_restantes: int = ataques - 1
	
	# Si nos quedan tiros por hacer, entramos al bucle
	if tiros_restantes ==0:
		return
	await get_tree().create_timer(0.1).timeout	
	for a in tiros_restantes:
		# Como ya disparó, primero se mueve una casilla hacia la dirección
		casilla_actual = casilla_actual + vector_direccion
		global_position = mapa.map_to_local(casilla_actual)
		
		# El jefe hace el siguiente disparo de la ráfaga
		shoot_projectile_at(player)
		if es_barrido:##si queremos que sea ataque barrido le ponemos true
			ataque_barrido(direccion)
		# Esperamos el pequeño bache de tiempo antes del siguiente tiro
		await get_tree().create_timer(0.1).timeout

func ataque_barrido(direccion:Tipo):
	ataque_direcciones(direccion)		

func ataque_circular(es_barrido:bool, cantidad_ataques:int)->void:
	var direcciones = [Tipo.NORTE,Tipo.ESTE,Tipo.SUR,Tipo.OESTE];
	var direcciones_horarias: Array[Tipo] = [
		Tipo.NORTE,    
		Tipo.NOR_ESTE, 
		Tipo.ESTE,      
		Tipo.SUR_ESTE,  
		Tipo.SUR,      
		Tipo.SUR_OESTE,
		Tipo.OESTE,     
		Tipo.NOR_OESTE
	]
	for d in direcciones_horarias:
		
		var casilla_jugador: Vector2i = mapa.local_to_map(player.global_position)
		
		var casilla_inicial_boss: Vector2i = casilla_jugador + (Vector2i(3, 3)*COORDENADAS[d])
		
		
		await _atacar_efecto(cantidad_ataques, casilla_inicial_boss, d,es_barrido)	
		
	animation_player.play(&"idle")
	
func ataque_direcciones(direccion:Tipo)->void:
	var direccion_enemigos = direccion_patron(direccion)
	
	##Seran 4 posiciones de enemigos para simular 5 disparos (4 + el boss)
	##los enemigos se generaran alado del jefe y si la direccion es una diagonal
	##como diagonal
	var posicion_boss = mapa.local_to_map(mapa.to_local(global_position))
	var posicion_player = mapa.local_to_map(mapa.to_local(player.global_position))
	
	var posiciones_disparos = patron_posiciones(posicion_boss,direccion_enemigos)
	var posiciones_target = patron_posiciones(posicion_player,direccion_enemigos)
	
	
	##si o si deben ser 4 disparos y 4 targets, sino crashea xd
	colocar_nodos(posiciones_disparos,disparos)
	colocar_nodos(posiciones_target,targets)
	
	##una vez colocado disparamos
	var i = 0
	for d in disparos:
		d.shoot_projectile_at(targets[i])
		i = i+1
		
func colocar_nodos(posiciones:Array[Vector2i],nodos:Array[Node2D])->void:
	var i = 0
	for n:Node2D in nodos:
		var pos = mapa.to_global(mapa.map_to_local(posiciones[i]))
		n.global_position = pos
		i = i+1

func reset_nodos(nodos:Array[Node2D], posicion_inicial:Vector2i):
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
	
	for e in targets.size()/2:
		posicion_iterada = posicion_iterada+direccion
		posiciones_nuevas.push_front(posicion_iterada)
		
	posicion_iterada = posicion
	direccion = direccion * (-1)
	
	var variacion = 0
	if(targets.size()%2==1):
		variacion = 1
	
	for e in targets.size()/2+variacion:
		posicion_iterada = posicion_iterada+direccion
		posiciones_nuevas.push_front(posicion_iterada)
	
	return posiciones_nuevas

func pausar_projectiles():
	velocidad_actual_projectil = projectile_speed

	for d in disparos:
		d.projectile_speed = 5	
	projectile_speed = 5	

func activar_projectiles(velocidad = null):
	if(velocidad==null):
		velocidad = 100		
	
	for p in get_tree().get_nodes_in_group("projectiles"):
		p.can_sleep = false
		p.speed = velocidad
		print(p.speed)
	
