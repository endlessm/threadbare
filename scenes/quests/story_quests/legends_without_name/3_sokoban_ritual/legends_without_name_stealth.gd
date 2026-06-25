extends Node2D

# CONFIGURACIÓN GENERAL
@export var tile_size: int = 64 

# NODOS DE LA ESCENA
@onready var mapa_paredes: Node2D = $TileMapLayers
@onready var player_node: Node2D = $Jugador 
@onready var contenedor_materiales: CharacterBody2D = $Materiales 

# VARIABLES DE ESTADO DEL JUEGO
var player_pos: Vector2i
var items: Array[Dictionary] = []
var historial: Array[Dictionary] = []
var space_pressed: bool = false
var juego_terminado: bool = false

# INICIALIZACIÓN DEL NIVEL
func _ready() -> void:
	player_pos = Vector2i(round(player_node.position.x / tile_size), round(player_node.position.y / tile_size))
	
	for child in contenedor_materiales.get_children():
		if child is Sprite2D:
			var pos_grid: Vector2i = Vector2i(round(child.position.x / tile_size), round(child.position.y / tile_size))
			var nombre: String = child.name.to_lower()
			var tipo: String = ""
			
			if "vela" in nombre: tipo = "vela"
			elif "espejo" in nombre: tipo = "espejo"
			elif "sal" in nombre: tipo = "sal"
			elif "moneda" in nombre: tipo = "moneda"
			elif "mana" in nombre: tipo = "mana"
			
			if tipo != "":
				items.append({
					"node": child,
					"pos": pos_grid,
					"id": tipo,
					"activo": true
				})
			
	actualizar_posiciones_visuales(false)

# BUCLE PRINCIPAL (CONTROLES)
func _process(_delta: float) -> void:
	if juego_terminado: return
	
	space_pressed = Input.is_action_pressed("ui_select") 
	
	if Input.is_action_just_pressed("ui_undo"):
		deshacer()
		return
		
	var dir: Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): dir = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down"): dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left"): dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right"): dir = Vector2i.RIGHT
	
	if dir != Vector2i.ZERO:
		mover(dir)

# DETECCIÓN DE COLISIONES (PAREDES)
func is_wall(pos: Vector2i) -> bool:
	for child in mapa_paredes.get_children():
		if "pared" in child.name.to_lower() and child.has_method("get_cell_source_id"):
			if child.get_cell_source_id(pos) != -1:
				return true
	return false

# GESTIÓN DE OBJETOS INTERACTIVOS
func get_item_at(pos: Vector2i) -> Dictionary:
	for item: Dictionary in items:
		if item["activo"] and item["pos"] == pos:
			return item
	return {}

func is_item_inactive(pos: Vector2i) -> bool:
	for item: Dictionary in items:
		if not item["activo"] and item["pos"] == pos:
			return true
	return false

# LÓGICA DE CONDICIÓN DE VICTORIA (EL ALTAR)
func get_ritual_target(pos: Vector2i) -> String:
	if pos == Vector2i(29, 13): return "vela"
	if pos == Vector2i(30, 13): return "espejo"
	if pos == Vector2i(31, 13): return "vela"
	if pos == Vector2i(29, 14): return "sal"
	if pos == Vector2i(30, 14): return "moneda"
	if pos == Vector2i(31, 14): return "sal"
	if pos == Vector2i(29, 15): return "vela"
	if pos == Vector2i(30, 15): return "mana"
	if pos == Vector2i(31, 15): return "vela" 
	return ""

func intentar_mover_item(item: Dictionary, dest: Vector2i) -> bool:
	if is_wall(dest) or not get_item_at(dest).is_empty() or is_item_inactive(dest):
		return false

	var target_id: String = get_ritual_target(dest)
	if target_id != "":
		var match_item: bool = (target_id == item["id"])
		
		if target_id == "mana" and item["id"] == "mana":
			var faltan_otros: bool = false
			for i: Dictionary in items:
				if i["id"] != "mana" and i["activo"]:
					faltan_otros = true
					break
			if faltan_otros:
				print("Rechazo: El Maná debe ir al final.")
				
				return false
			else:
				match_item = true
		
		if match_item:
			item["activo"] = false
			item["pos"] = dest
			check_win()
			return true

	item["pos"] = dest
	return true

# LÓGICA PRINCIPAL DE MOVIMIENTO
func mover(dir: Vector2i) -> void:
	var next_pos: Vector2i = player_pos + dir
	
	if is_wall(next_pos) or is_item_inactive(next_pos): return
	
	var estado_items: Array[Dictionary] = []
	for i: Dictionary in items:
		estado_items.append({"pos": i["pos"], "activo": i["activo"]})
	var estado_previo: Dictionary = {"player_pos": player_pos, "items": estado_items}
	
	var accion_exitosa: bool = false

	if space_pressed:
		if not get_item_at(next_pos).is_empty(): return 
		
		var pos_atras: Vector2i = player_pos - dir
		var obj_jalado: Dictionary = get_item_at(pos_atras)
		var pos_vieja: Vector2i = player_pos
		
		player_pos = next_pos
		accion_exitosa = true
		
		if not obj_jalado.is_empty():
			if not intentar_mover_item(obj_jalado, pos_vieja):
				player_pos = pos_vieja 
				accion_exitosa = false
	else:
		var obj_empujado: Dictionary = get_item_at(next_pos)
		
		if not obj_empujado.is_empty():
			var dest: Vector2i = next_pos + dir
			var movido: bool = intentar_mover_item(obj_empujado, dest)
			
			# Nota: Dejo esta sección por si es una mecánica de deslizamiento propia de tu juego
			if not movido and is_wall(dest):
				var alt1: Vector2i = next_pos + (Vector2i.LEFT if dir.y != 0 else Vector2i.UP)
				var alt2: Vector2i = next_pos + (Vector2i.RIGHT if dir.y != 0 else Vector2i.DOWN)
				
				var libre1: bool = not is_wall(alt1) and get_item_at(alt1).is_empty() and not is_item_inactive(alt1)
				var libre2: bool = not is_wall(alt2) and get_item_at(alt2).is_empty() and not is_item_inactive(alt2)
				
				if libre1 and not libre2: movido = intentar_mover_item(obj_empujado, alt1)
				elif libre2 and not libre1: movido = intentar_mover_item(obj_empujado, alt2)
			
			if movido:
				player_pos = next_pos
				accion_exitosa = true
		else:
			player_pos = next_pos
			accion_exitosa = true

	if accion_exitosa:
		historial.push_back(estado_previo)
		if historial.size() > 250: historial.pop_front()
		actualizar_posiciones_visuales(true)

# FUNCIONALIDADES ADICIONALES (DESHACER Y UI)
func deshacer() -> void:
	if historial.size() > 0:
		var estado: Dictionary = historial.pop_back()
		player_pos = estado["player_pos"]
		for i: int in range(items.size()):
			items[i]["pos"] = estado["items"][i]["pos"]
			items[i]["activo"] = estado["items"][i]["activo"]
		actualizar_posiciones_visuales(true)

func check_win() -> void:
	var todos_colocados: bool = true
	for i: Dictionary in items:
		if i["activo"]: todos_colocados = false
		
	if todos_colocados:
		juego_terminado = true
		print("¡RITUAL COMPLETADO!")
		
		# 1. Esperamos 2 segundos para que el jugador alcance a ver 
		# que colocó la última pieza antes de cambiar de pantalla de golpe
		await get_tree().create_timer(2).timeout
		
		# 2. Cambiamos a la escena del siguiente nivel
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/legends_without_name/4_outro/legends_without_name_outro.tscn")

func actualizar_posiciones_visuales(animar: bool = false) -> void:
	var player_target_pixel: Vector2 = Vector2(player_pos * tile_size)
	
	if animar:
		# Creamos UN SOLO TWEEN y lo configuramos en paralelo
		var tween: Tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(player_node, "position", player_target_pixel, 0.1)
		
		for i: Dictionary in items:
			var target_pos: Vector2 = Vector2(i["pos"] * tile_size)
			tween.tween_property(i["node"], "position", target_pos, 0.1)
			
			if not i["activo"]:
				i["node"].modulate = Color(1.2, 1.2, 2.0) 
			else:
				i["node"].modulate = Color(1, 1, 1)
	else:
		player_node.position = player_target_pixel
		for i: Dictionary in items:
			i["node"].position = Vector2(i["pos"] * tile_size)
			if not i["activo"]:
				i["node"].modulate = Color(1.2, 1.2, 2.0) 
			else:
				i["node"].modulate = Color(1, 1, 1)
