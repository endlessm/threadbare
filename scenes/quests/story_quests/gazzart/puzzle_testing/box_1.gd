# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RigidBody2D

## Emitida cuando la caja se mueve
## Parámetros: nueva_posicion, direccion_movimiento
signal caja_movida(new_position: Vector2, direccion: Vector2)

## Distancia a la que detecta al jugador para empujar
@export var deteccion: float = 60.0

## Distancia que se mueve la caja cuando es empujada (en píxeles)
@export var empuje: float = 64.0

var nodo_jugador: Player = null
var cooldown_empuje: float = 0.0
var tiempo_cooldown: float = 0.2
var tablero_tilemap: TileMapLayer = null

func _ready() -> void:
	# Configurar propiedades de física
	gravity_scale = 0  # Sin gravedad
	lock_rotation = true  # No rotar
	linear_damp = 10.0  # Fricción alta para detener cualquier movimiento residual
	mass = 2.0  # Peso de la caja
	# Congelar la física para movimiento directo
	freeze = true
	
	# Obtener referencia al tilemap del tablero
	tablero_tilemap = get_node_or_null("../../Baldosas_Tablero") as TileMapLayer
	if not tablero_tilemap:
		print("Advertencia: No se encontró el tilemap del tablero (Baldosas_Tablero)")


func _physics_process(delta: float) -> void:
	# Reducir el cooldown
	if cooldown_empuje > 0.0:
		cooldown_empuje -= delta
	
	# Buscar al jugador en el árbol de escena
	if not nodo_jugador:
		nodo_jugador = get_tree().get_first_node_in_group("player") as Player
	
	# Detectar cuando el jugador presiona la tecla de interacción
	if Input.is_action_just_pressed(&"interact"):
		_calcular_movimiento()


func _calcular_movimiento() -> void:
	# Verificar que el jugador existe y el cooldown terminó
	if not nodo_jugador or cooldown_empuje > 0.0:
		return
	
	# Obtener el centro visual de la caja (usando el CollisionShape2D si existe)
	var centro_caja = global_position
	var colision_caja = get_node_or_null("CollisionShape2D")
	if colision_caja:
		centro_caja = colision_caja.global_position
	
	# Verificar que el jugador está cerca
	var distancia = centro_caja.distance_to(nodo_jugador.global_position)
	if distancia >= deteccion:
		return
	
	# Calcular la posición relativa del jugador respecto al centro de la caja
	var posicion_relativa = nodo_jugador.global_position - centro_caja
	
	# Determinar en qué lado está el jugador y mover la caja en la dirección opuesta
	var direccion_empuje = _obtener_direccion_empuje(posicion_relativa)
	
	if direccion_empuje != Vector2.ZERO:
		_mover_la_caja(direccion_empuje)
		cooldown_empuje = tiempo_cooldown


func _obtener_direccion_empuje(ubi_relativa: Vector2) -> Vector2:
	# Determinar en qué lado está el jugador y retornar la dirección de empuje
	var abs_x = abs(ubi_relativa.x)
	var abs_y = abs(ubi_relativa.y)
	
	# Usar un umbral para determinar la dirección dominante
	var dire_principal = 15.0
	
	# Si X es más dominante
	if abs_x > (abs_y + dire_principal):
		# Jugador está a la izquierda o derecha de la caja
		if ubi_relativa.x < 0:
			# Jugador está a la IZQUIERDA → caja se mueve a la DERECHA
			return Vector2(1, 0)
		else:
			# Jugador está a la DERECHA → caja se mueve a la IZQUIERDA
			return Vector2(-1, 0)
	# Si Y es más dominante
	elif abs_y > (abs_x + dire_principal):
		# Jugador está arriba o abajo de la caja
		# INVERTIDO: la condición también está invertida
		if ubi_relativa.y < 0:
			# Jugador está ARRIBA (Y negativo) → caja se mueve hacia ABAJO (Y positivo = abajo)
			return Vector2(0, 1)
		else:
			# Jugador está ABAJO (Y positivo) → caja se mueve hacia ARRIBA (Y negativo = arriba)
			return Vector2(0, -1)
	# Si están muy cerca o diagonal, usar la dirección más fuerte
	else:
		if abs_x > abs_y:
			# Más horizontal
			if ubi_relativa.x < 0:
				return Vector2(1, 0)
			else:
				return Vector2(-1, 0)
		else:
			# Más vertical - condición invertida
			if ubi_relativa.y < 0:
				return Vector2(0, 1)  # Jugador arriba → caja abajo
			else:
				return Vector2(0, -1)  # Jugador abajo → caja arriba


func _mover_la_caja(direccion: Vector2) -> void:
	# Detener cualquier movimiento actual
	linear_velocity = Vector2.ZERO
	
	# Calcular la nueva posición del RigidBody2D
	var nueva_posicion = global_position + (direccion * empuje)
	
	# Obtener la posición real de la caja (usando CollisionShape2D si existe)
	var posicion_real_caja = nueva_posicion
	var colision_caja = get_node_or_null("CollisionShape2D")
	if colision_caja:
		# Calcular la posición global del CollisionShape2D en la nueva posición
		posicion_real_caja = nueva_posicion + colision_caja.position
	
	# Verificar que la nueva posición esté dentro del tablero
	if not _posicion_valida_en_tablero(posicion_real_caja):
		# Si no es válida, no mover la caja
		return
	
	# Mover la caja instantáneamente
	global_position = nueva_posicion
	
	# Emitir señal para notificar que la caja se movió (incluyendo la dirección)
	caja_movida.emit(nueva_posicion, direccion)


func _posicion_valida_en_tablero(posicion: Vector2) -> bool:
	# Si no hay tilemap, permitir el movimiento (por compatibilidad)
	if not tablero_tilemap:
		return true
	
	# Convertir la posición global a coordenadas locales del tilemap
	var posicion_local = tablero_tilemap.to_local(posicion)
	
	# Convertir a coordenadas de celda del tilemap
	var coordenadas_celda = tablero_tilemap.local_to_map(posicion_local)
	
	# Verificar si hay un tile válido en esa celda
	# get_cell_source_id retorna -1 si no hay tile
	var source_id = tablero_tilemap.get_cell_source_id(coordenadas_celda)
	
	# Si source_id es -1, no hay tile, por lo que la posición no es válida
	return source_id != -1
