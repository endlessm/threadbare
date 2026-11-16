extends RigidBody2D

## Señal emitida cuando Box2 se mueve
signal caja_movida(new_position: Vector2, direccion: Vector2)

var caja1: RigidBody2D = null
var tablero_tilemap: TileMapLayer = null

## Distancia que se mueve la caja cuando es empujada (debe ser igual a Box1)
@export var empuje: float = 64.0

func _ready() -> void:
	# Obtener referencia a Box1
	caja1 = get_node_or_null("../Box1")
	
	# Obtener referencia al tilemap del tablero
	tablero_tilemap = get_node_or_null("../../Baldosas_Tablero") as TileMapLayer
	if not tablero_tilemap:
		print("Advertencia: No se encontró el tilemap del tablero (Baldosas_Tablero) en Box2")
	
	if caja1:
		# Conectar la señal de Box1 para que Box2 se mueva cuando Box1 se mueva
		caja1.caja_movida.connect(_caja1_movimiento)
	else:
		print("Error: No se encontró Box1")


func _caja1_movimiento(new_position: Vector2, direccion: Vector2) -> void:
	# Esta función se llama cada vez que Box1 se mueve
	# Intentar mover Box2 en la misma dirección que Box1
	_intentar_mover_caja(direccion)


func _intentar_mover_caja(direccion: Vector2) -> void:
	# Calcular la nueva posición moviendo Box2 en la misma dirección
	var nueva_posicion = global_position + (direccion * empuje)
	
	# Obtener la posición real de la caja (usando CollisionShape2D si existe)
	var posicion_real_caja = nueva_posicion
	var colision_caja = get_node_or_null("CollisionShape2D")
	if colision_caja:
		# Calcular la posición global del CollisionShape2D en la nueva posición
		posicion_real_caja = nueva_posicion + colision_caja.position
	
	# Verificar que la nueva posición esté dentro del tablero
	# Si no es válida, simplemente no mover Box2 (mantener posición actual)
	if _posicion_valida_en_tablero(posicion_real_caja):
		# Mover Box2 a la nueva posición
		global_position = nueva_posicion
		
		# Emitir señal para notificar que Box2 se movió
		caja_movida.emit(global_position, direccion)


func _posicion_valida_en_tablero(posicion_centro: Vector2) -> bool:
	# Si no hay tilemap, permitir el movimiento (por compatibilidad)
	if not tablero_tilemap:
		return true
	
	# Obtener el tamaño de la caja (64x64 según el CollisionShape2D)
	var tamano_caja = Vector2(64, 64)
	var colision_caja = get_node_or_null("CollisionShape2D")
	if colision_caja and colision_caja.shape is RectangleShape2D:
		tamano_caja = (colision_caja.shape as RectangleShape2D).size
	
	# Verificar múltiples puntos de la caja: centro y esquinas
	# Usar un margen más pequeño para evitar problemas de precisión
	var margen = 0.3  # Margen para evitar problemas en los bordes
	var puntos_verificar = [
		posicion_centro,  # Centro
		posicion_centro + Vector2(-tamano_caja.x * 0.5 + margen, -tamano_caja.y * 0.5 + margen),  # Esquina superior izquierda
		posicion_centro + Vector2(tamano_caja.x * 0.5 - margen, -tamano_caja.y * 0.5 + margen),   # Esquina superior derecha
		posicion_centro + Vector2(-tamano_caja.x * 0.5 + margen, tamano_caja.y * 0.5 - margen),  # Esquina inferior izquierda
		posicion_centro + Vector2(tamano_caja.x * 0.5 - margen, tamano_caja.y * 0.5 - margen),   # Esquina inferior derecha
	]
	
	# Verificar que todos los puntos estén en tiles válidos
	for punto in puntos_verificar:
		# Convertir la posición global a coordenadas locales del tilemap
		var posicion_local = tablero_tilemap.to_local(punto)
		
		# Convertir a coordenadas de celda del tilemap
		var coordenadas_celda = tablero_tilemap.local_to_map(posicion_local)
		
		# Verificar si hay un tile válido en esa celda
		# get_cell_source_id retorna -1 si no hay tile
		var source_id = tablero_tilemap.get_cell_source_id(coordenadas_celda)
		
		# Si source_id es -1, no hay tile, por lo que la posición no es válida
		if source_id == -1:
			return false
	
	# Todos los puntos están en tiles válidos
	return true
	
