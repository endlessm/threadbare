class_name BalderFuturo
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
enum Patron{
	CRUZ,
	EQUIS,
	CIRCULO
}
const patron_direcciones: Dictionary={
	Patron.CRUZ: [Tipo.NORTE,Tipo.ESTE,Tipo.SUR,Tipo.OESTE],
	Patron.CIRCULO: [
		Tipo.NORTE,    
		Tipo.NOR_ESTE, 
		Tipo.ESTE,      
		Tipo.SUR_ESTE,  
		Tipo.SUR,      
		Tipo.SUR_OESTE,
		Tipo.OESTE,     
		Tipo.NOR_OESTE
	],
	Patron.EQUIS: [
		Tipo.NOR_ESTE, 
		Tipo.SUR_ESTE,  
		Tipo.SUR_OESTE,
		Tipo.NOR_OESTE
	]
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

var espaciado = 1 ##VARIABLE QUE CONTROLARA EL ESPACIADO DE LOS PROYECTILES
var velocidad_actual_projectil:int
@export var fase1:bool = false
@export var fase2:bool = false
@export var fase3:bool = false
func _atacar_efecto(ataques: int, casilla_a_mover: Vector2i, direccion: Tipo, es_barrido:bool) -> void:
	global_position = mapa.map_to_local(casilla_a_mover)
	##ejecuta su ataque por defecto (Disparo 1)
	_is_attacking = true
	animation_player.play(&"attack")
	await atacar_sonido()
	if es_barrido:##si queremos que sea ataque barrido le ponemos true
		await ataque_barrido(direccion)
	await get_tree().create_timer(0.3).timeout		
	pausar_projectiles()		
	var vector_direccion: Vector2i = COORDENADAS[direccion]
	var casilla_actual: Vector2i = casilla_a_mover
	
	##Calculamos cuántos tiros quedan pendientes
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
			await ataque_barrido(direccion)
		%DisparoPolyfonic.play_audio()	
		pausar_projectiles()	
		# Esperamos el pequeño bache de tiempo antes del siguiente tiro
		await get_tree().create_timer(0.1).timeout

func _atacar_efecto_circular(casilla_a_mover: Vector2i,rafagas:int):
	global_position = mapa.map_to_local(casilla_a_mover)
	_is_attacking = true
	animation_player.play(&"attack")
	await animation_player.animation_finished
	await _ataque_circular_rafaga(rafagas,true)
	pausar_projectiles()		
	await get_tree().create_timer(0.1).timeout	

	

func ataque_barrido(direccion:Tipo):
	var direccion_enemigos = direccion_patron(direccion)
	ataque_direcciones(direccion_enemigos)		

func ataque_circular(es_barrido:bool, cantidad_ataques:int, patron)->void:

	var direcciones = patron_direcciones[patron]
	for d in direcciones:
		var casilla_jugador: Vector2i = mapa.local_to_map(player.global_position)
		
		var casilla_inicial_boss: Vector2i = casilla_jugador + (Vector2i(5, 5)*COORDENADAS[d])
		
		await _atacar_efecto(cantidad_ataques, casilla_inicial_boss, d,es_barrido)	
	animation_player.play(&"idle")
	
func ataque_direcciones(direccion:Vector2i)->void:
	
	##Seran 4 posiciones de enemigos para simular 5 disparos (4 + el boss)
	##los enemigos se generaran alado del jefe y si la direccion es una diagonal
	##como diagonal
	var posicion_boss = mapa.local_to_map(mapa.to_local(global_position))
	var posicion_player = mapa.local_to_map(mapa.to_local(player.global_position))
	
	var posiciones_disparos = patron_posiciones(posicion_boss,direccion)
	var posiciones_target = patron_posiciones(posicion_player,direccion)
	
	
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
		##cambiar el 2 si queremos balas mas acumuladas o no
		posicion_iterada = posicion_iterada+(direccion*espaciado)
		posiciones_nuevas.push_front(posicion_iterada)
		
	posicion_iterada = posicion
	direccion = direccion * (-1)
	
	var variacion = 0
	if(targets.size()%2==1):
		variacion = 1
	
	for e in targets.size()/2+variacion:
		posicion_iterada = posicion_iterada+(direccion*espaciado)
		posiciones_nuevas.push_front(posicion_iterada)
	
	return posiciones_nuevas

func pausar_projectiles():
	for p in get_tree().get_nodes_in_group("projectiles"):
		p.process_mode = Node.PROCESS_MODE_DISABLED
	
func activar_projectiles():
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p is Projectile:
			p.process_mode = Node.PROCESS_MODE_INHERIT
	
	
signal termino_ataque				

var time_stop = false
var is_stopping = false
@export var contador_ataque_time_stop: Timer

func _on_timeout() -> void:
	contador_ataque_time_stop.paused = true
	var player: Player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	_is_attacking = true
	animation_player.play(&"attack")
	if fase2 && !fase3:
		await atacar_sonido()
		
		var direccion = global_position.direction_to(player.global_position)
		direccion = direccion.rotated(-PI / 2)
		ataque_direcciones(direccion.round())
	elif fase3 &&!time_stop:
		await atacar_sonido()
		
		timer.paused = true
		await _ataque_circular_rafaga(4,false)
		if !is_stopping:
			timer.paused = false
	else:
		await atacar_sonido()
				
	animation_player.queue(&"idle")		
	contador_ataque_time_stop.paused =false
	termino_ataque.emit()

func atacar_sonido()->void:
	await await get_tree().create_timer(0.7).timeout
	%DisparoPolyfonic.play_audio()

func _ataque_circular_rafaga(ataques:int,es_espiral:bool)->void:
	%PatronCircular.global_position = self.global_position
	var puntos = %PatronCircular.get_children()
	for i in ataques:
		if !es_espiral:
			for p in puntos:
				shoot_projectile_at(p)
			%PatronCircular.rotation += 0.1
			%DisparoPolyfonic.play_audio()
			await get_tree().create_timer(0.8).timeout

var ataque_activo = false

var tiempo_ultimo_sonido : float = 0.0
var tiempo_ultimo_sonido2 : float = 0.0
const COOLDOWN_SONIDO : float = 0.12			
func _ataque_espiral()->void:
	ataque_activo = true
	%PatronCircular.global_position = self.global_position
	var puntos = %PatronCircular.get_children()
	while ataque_activo:
		for p in puntos:
			if not ataque_activo:
				break
			shoot_projectile_at(p)
			%PatronCircular.rotation += 0.1
			
			var tiempo_actual = Time.get_ticks_msec() / 1000.0
			if tiempo_actual - tiempo_ultimo_sonido >= COOLDOWN_SONIDO:
				%DisparoPolyfonic.play_audio()
				tiempo_ultimo_sonido = tiempo_actual
			await get_tree().create_timer(0.05).timeout				

func _ataque_cardinales()->void:
	ataque_activo =true
	%PatronCircular.global_position = self.global_position
	
	var iterador = 0
	var puntos = %PatronCircular.cardinales[iterador]
	while ataque_activo:
		%DisparoPolyfonic.play_audio()
		for p in puntos:
			if not ataque_activo:
				break
			shoot_projectile_at(p)
		await get_tree().create_timer(0.5).timeout
		iterador =iterador+1	
		puntos = %PatronCircular.cardinales[iterador%2]

func _ataque_final_()->void:
	ataque_activo =true
	%PatronCircular.global_position = self.global_position
	
	var iterador = 0
	var puntos = %PatronCircular.cardinales[iterador]
	var ndisparos=5
	while ataque_activo:
		for p in puntos:
			if not ataque_activo:
				break
				
			shoot_projectile_at(p)
			var tiempo_actual = Time.get_ticks_msec() / 1000.0
			if tiempo_actual - tiempo_ultimo_sonido2 >= COOLDOWN_SONIDO:
				%DisparoPolyfonic.play_audio()
				tiempo_ultimo_sonido2= tiempo_actual
		await get_tree().create_timer(0.05).timeout
		ndisparos = ndisparos-1
		if ndisparos<1:
			iterador =iterador+1	
			puntos = %PatronCircular.cardinales[iterador%2]
			ndisparos=10

func _ejecutar_ataque_espera()->void:
	if fase1:
		_ataque_cardinales()
		return
	if fase2:
		_ataque_espiral()
		return	
	if fase3:
		_ataque_final_()
		return		
func _on_got_hit(body: Node2D) -> void:
	if body is Projectile and not body.can_hit_enemy and not _is_defeated:
		return
	body.queue_free()
	##animation_player.play(&"got hit")	
