extends Node2D

# Configuración de movimiento para diferentes tipos de objetos
@export_group("Configuración de Movimiento")
@export var movimiento_activado: bool = true
@export var intensidad_movimiento: float = 1.0
@export var velocidad_global: float = 2.0

# Variables internas
var tiempo: float = 0.0
var objetos_con_movimiento: Array[Dictionary] = []

func _ready() -> void:
	# Encontrar y configurar todos los objetos decorativos
	configurar_objetos_decorativos()

func _process(delta: float) -> void:
	if not movimiento_activado:
		return
		
	tiempo += delta * velocidad_global
	actualizar_movimiento_objetos()

func configurar_objetos_decorativos() -> void:
	objetos_con_movimiento.clear()
	
	# Buscar todos los nodos que deben tener movimiento
	var nodos_con_movimiento: Array[Node2D] = encontrar_nodos_con_movimiento()
	
	for nodo: Node2D in nodos_con_movimiento:
		var config: Dictionary = obtener_configuracion_objeto(nodo.name)
		if config["activado"]:
			objetos_con_movimiento.append({
				"nodo": nodo,
				"config": config,
				"posicion_original": nodo.position,
				"rotacion_original": nodo.rotation,
				"escala_original": nodo.scale,
				"offset_aleatorio": randf() * 100.0  # Para que no se muevan todos igual
			})

func encontrar_nodos_con_movimiento() -> Array[Node2D]:
	var nodos: Array[Node2D] = []
	
	# Buscar por nombres específicos
	var patrones: Array[String] = [
		"candle", "vela", "torch", "tumba", "adornos",
		"candelabro", "antorcha", "lámpara", "luz"
	]
	
	# Recorrer todos los nodos hijos recursivamente
	buscar_nodos_recursivamente(self, patrones, nodos)
	
	return nodos

func buscar_nodos_recursivamente(nodo_actual: Node, patrones: Array[String], resultados: Array[Node2D]) -> void:
	for hijo: Node in nodo_actual.get_children():
		if hijo is Node2D:
			var nombre: String = hijo.name.to_lower()
			
			# Verificar si el nombre coincide con algún patrón
			for patron: String in patrones:
				if patron in nombre:
					resultados.append(hijo as Node2D)
					break
			
			# Buscar recursivamente en los hijos
			buscar_nodos_recursivamente(hijo, patrones, resultados)

func obtener_configuracion_objeto(nombre: String) -> Dictionary:
	var nombre_lower: String = nombre.to_lower()
	var config: Dictionary = {
		"activado": true,
		"tipo_movimiento": "flotar",
		"amplitud": 2.0,
		"velocidad": 1.0,
		"rotar": false
	}
	
	# Configuraciones específicas por tipo de objeto
	if "candle" in nombre_lower or "vela" in nombre_lower:
		config["tipo_movimiento"] = "llama"
		config["amplitud"] = 3.0 * intensidad_movimiento
		config["velocidad"] = 3.0
		config["rotar"] = false
	elif "torch" in nombre_lower:
		config["tipo_movimiento"] = "llama" 
		config["amplitud"] = 4.0 * intensidad_movimiento
		config["velocidad"] = 2.5
		config["rotar"] = false
	elif "tumba" in nombre_lower:
		config["tipo_movimiento"] = "flotar"
		config["amplitud"] = 1.0 * intensidad_movimiento
		config["velocidad"] = 0.5
		config["rotar"] = false
	elif "adornos" in nombre_lower:
		config["tipo_movimiento"] = "rotar"
		config["amplitud"] = 0.5 * intensidad_movimiento
		config["velocidad"] = 1.0
		config["rotar"] = true
	
	return config

func actualizar_movimiento_objetos() -> void:
	for objeto: Dictionary in objetos_con_movimiento:
		var nodo: Node2D = objeto["nodo"]
		var config: Dictionary = objeto["config"]
		var pos_original: Vector2 = objeto["posicion_original"]
		var rot_original: float = objeto["rotacion_original"]
		var offset: float = objeto["offset_aleatorio"]
		
		var tiempo_objeto: float = tiempo + offset
		
		match config["tipo_movimiento"]:
			"flotar":
				# Movimiento de flotación suave
				var movimiento_y: float = sin(tiempo_objeto * config["velocidad"]) * config["amplitud"]
				nodo.position.y = pos_original.y + movimiento_y
				
			"llama":
				# Movimiento más irregular como llama
				var movimiento_y: float = sin(tiempo_objeto * config["velocidad"]) * config["amplitud"]
				var movimiento_x: float = cos(tiempo_objeto * config["velocidad"] * 0.7) * (config["amplitud"] * 0.3)
				nodo.position = pos_original + Vector2(movimiento_x, movimiento_y)
				
			"rotar":
				# Rotación suave
				if config["rotar"]:
					nodo.rotation = rot_original + sin(tiempo_objeto * config["velocidad"]) * config["amplitud"] * 0.1

# Funciones para controlar el movimiento desde otros scripts
func activar_movimiento() -> void:
	movimiento_activado = true

func desactivar_movimiento() -> void:
	movimiento_activado = false

func cambiar_intensidad(nueva_intensidad: float) -> void:
	intensidad_movimiento = nueva_intensidad
	# Reconfigurar objetos con nueva intensidad
	configurar_objetos_decorativos()
	
