extends TileMapLayer

# Configuración de movimiento para objetos estáticos
@export_group("Configuración de Movimiento Sutil")
@export var movimiento_activado: bool = false  # Desactivado por defecto
@export var intensidad_movimiento: float = 5.0
@export var velocidad_global: float = 3.0

# Variables internas
var tiempo: float = 0.0
var objetos_estaticos_con_movimiento: Array[Dictionary] = []

func _ready() -> void:
	if movimiento_activado:
		print("=== INICIANDO SCRIPT DE MOVIMIENTO EN MAIN ===")
		# Esperar un frame para asegurar que todos los nodos estén listos
		await get_tree().process_frame
		# Encontrar y configurar solo objetos estáticos
		configurar_objetos_estaticos()

func _process(delta: float) -> void:
	if not movimiento_activado:
		return
		
	tiempo += delta * velocidad_global
	actualizar_movimiento_sutil()

func configurar_objetos_estaticos() -> void:
	objetos_estaticos_con_movimiento.clear()
	
	# Buscar solo objetos que deberían ser estáticos pero queremos darles movimiento sutil
	var nodos_estaticos: Array[Node2D] = encontrar_objetos_estaticos()
	
	print("Nodos estáticos encontrados: ", nodos_estaticos.size())
	for nodo in nodos_estaticos:
		print(" - ", nodo.name, " en posición: ", nodo.position)
		var config: Dictionary = obtener_configuracion_objeto_estatico(nodo.name)
		if config["activado"]:
			objetos_estaticos_con_movimiento.append({
				"nodo": nodo,
				"config": config,
				"posicion_original": nodo.position,
				"offset_aleatorio": randf() * 100.0
			})
	
	print("Objetos configurados para movimiento: ", objetos_estaticos_con_movimiento.size())
	
	# Si no se encontraron objetos, mostrar advertencia
	if objetos_estaticos_con_movimiento.size() == 0:
		print("ADVERTENCIA: No se encontraron objetos para animar. Revisa los nombres.")

func encontrar_objetos_estaticos() -> Array[Node2D]:
	var nodos: Array[Node2D] = []
	
	# Buscar solo objetos que normalmente serían estáticos
	var patrones_estaticos: Array[String] = [
		"tumba", "adornos", "carlute", "candle", "vela", "torch"
	]
	
	print("Buscando objetos con patrones: ", patrones_estaticos)
	
	# Recorrer todos los nodos hijos recursivamente empezando desde Main
	buscar_nodos_estaticos_recursivamente(self, patrones_estaticos, nodos)
	
	return nodos

func buscar_nodos_estaticos_recursivamente(nodo_actual: Node, patrones: Array[String], resultados: Array[Node2D]) -> void:
	for hijo: Node in nodo_actual.get_children():
		if hijo is Node2D:
			var nombre: String = hijo.name.to_lower()
			var nodo_2d: Node2D = hijo as Node2D
			
			# Verificar si el nombre coincide con algún patrón de objeto estático
			for patron: String in patrones:
				if patron in nombre:
					# Excluir objetos que ya tienen animaciones propias
					if not tiene_animacion_propia(nodo_2d):
						resultados.append(nodo_2d)
						print("OBJETO ENCONTRADO: ", nombre, " (", hijo.name, ")")
					else:
						print("OBJETO EXCLUIDO (tiene animación): ", nombre, " (", hijo.name, ")")
					break
			
			# Buscar recursivamente en los hijos
			buscar_nodos_estaticos_recursivamente(hijo, patrones, resultados)

func tiene_animacion_propia(nodo: Node2D) -> bool:
	# Verificar si el nodo o sus hijos tienen componentes de animación
	if nodo is AnimatedSprite2D:
		return true
	
	# Verificar si tiene un AnimationPlayer como hijo
	for hijo: Node in nodo.get_children():
		if hijo is AnimatedSprite2D or hijo is AnimationPlayer:
			return true
	
	return false

func obtener_configuracion_objeto_estatico(nombre: String) -> Dictionary:
	var nombre_lower: String = nombre.to_lower()
	var config: Dictionary = {
		"activado": true,
		"tipo_movimiento": "flotar",
		"amplitud": 5.0,  # Aumenté significativamente la amplitud
		"velocidad": 2.0   # Aumenté significativamente la velocidad
	}
	
	# Configuraciones específicas por tipo de objeto estático
	if "tumba" in nombre_lower:
		config["tipo_movimiento"] = "flotar"
		config["amplitud"] = 3.0 * intensidad_movimiento
		config["velocidad"] = 1.5
	elif "adornos" in nombre_lower:
		config["tipo_movimiento"] = "rotar"
		config["amplitud"] = 2.0 * intensidad_movimiento
		config["velocidad"] = 2.0
	elif "carlute" in nombre_lower:
		config["tipo_movimiento"] = "flotar"
		config["amplitud"] = 2.5 * intensidad_movimiento
		config["velocidad"] = 2.0
	elif "candle" in nombre_lower or "vela" in nombre_lower:
		config["tipo_movimiento"] = "llama"
		config["amplitud"] = 6.0 * intensidad_movimiento
		config["velocidad"] = 4.0
	elif "torch" in nombre_lower:
		config["tipo_movimiento"] = "llama"
		config["amplitud"] = 8.0 * intensidad_movimiento
		config["velocidad"] = 3.0
	
	print("Configuración para ", nombre, ": ", config)
	return config

func actualizar_movimiento_sutil() -> void:
	for objeto: Dictionary in objetos_estaticos_con_movimiento:
		var nodo: Node2D = objeto["nodo"]
		var config: Dictionary = objeto["config"]
		var pos_original: Vector2 = objeto["posicion_original"]
		var offset: float = objeto["offset_aleatorio"]
		
		var tiempo_objeto: float = tiempo + offset
		
		match config["tipo_movimiento"]:
			"flotar":
				# Movimiento de flotación
				var movimiento_y: float = sin(tiempo_objeto * config["velocidad"]) * config["amplitud"]
				nodo.position.y = pos_original.y + movimiento_y
				# Debug: mostrar movimiento si es significativo
				if abs(movimiento_y) > 1.0:
					print(nodo.name, " moviéndose Y: ", movimiento_y)
				
			"llama":
				# Movimiento de llama (más irregular)
				var movimiento_y: float = sin(tiempo_objeto * config["velocidad"]) * config["amplitud"]
				var movimiento_x: float = cos(tiempo_objeto * config["velocidad"] * 1.7) * (config["amplitud"] * 0.4)
				nodo.position = pos_original + Vector2(movimiento_x, movimiento_y)
				# Debug: mostrar movimiento si es significativo
				if abs(movimiento_y) > 1.0 or abs(movimiento_x) > 1.0:
					print(nodo.name, " moviéndose X: ", movimiento_x, " Y: ", movimiento_y)
				
			"rotar":
				# Rotación
				var rotacion: float = sin(tiempo_objeto * config["velocidad"]) * config["amplitud"] * 0.1
				nodo.rotation = rotacion
				# Debug: mostrar rotación si es significativa
				if abs(rotacion) > 0.05:
					print(nodo.name, " rotando: ", rotacion)

# Función para probar el movimiento manualmente
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("=== REINICIANDO CONFIGURACIÓN DE MOVIMIENTO ===")
		configurar_objetos_estaticos()

# Funciones para controlar el movimiento desde otros scripts
func activar_movimiento() -> void:
	movimiento_activado = true
	print("Movimiento ACTIVADO")

func desactivar_movimiento() -> void:
	movimiento_activado = false
	print("Movimiento DESACTIVADO")

func cambiar_intensidad(nueva_intensidad: float) -> void:
	intensidad_movimiento = nueva_intensidad
	print("Nueva intensidad: ", intensidad_movimiento)
	# Reconfigurar objetos con nueva intensidad
	configurar_objetos_estaticos()
