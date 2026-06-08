extends Node2D

var player_hp: int = 3
var is_player_invulnerable: bool = false
var combat_started: bool = false

var player_start_pos: Vector2 = Vector2.ZERO
var player_node: Node = null

var _hidden_ui_nodes: Array[CanvasItem] = []

# --- SISTEMA DE OLEADAS Y COLECCIONABLE ---
var current_wave: int = 1
var max_waves: int = 3
var enemies_defeated_in_current_wave: int = 0
var collectible_node: Node = null

# Enemigos por oleada (Wave 1: 3, Wave 2: 5, Wave 3: 7)
var enemies_per_wave: Array[int] = [3, 5, 7] 

func _ready() -> void:
	player_node = find_child("Player", true, false)
	if player_node:
		player_start_pos = player_node.global_position
		player_node.set_collision_mask_value(3, true)
		
		var repel_node: Node = player_node.get_node_or_null("%PlayerRepel")
		if repel_node:
			repel_node.input_action = "attack" 

	# Transparencia del HUD Ninja
	var root: Window = get_tree().root
	var viejo_letrero: CanvasItem = root.find_child("RepelInputHint", true, false) as CanvasItem
	if is_instance_valid(viejo_letrero):
		viejo_letrero.modulate.a = 0.0 
		_hidden_ui_nodes.append(viejo_letrero)
		
	# --- OCULTAR HILO COLECCIONABLE AL INICIO ---
	collectible_node = find_child("CollectibleItem", true, false)
	if collectible_node:
		collectible_node.hide()
		collectible_node.process_mode = Node.PROCESS_MODE_DISABLED

func _exit_tree() -> void:
	for node in _hidden_ui_nodes:
		if is_instance_valid(node): 
			node.modulate.a = 1.0
	_hidden_ui_nodes.clear()

func _process(_delta: float) -> void:
	if not combat_started and player_node:
		if player_node.mode == Player.Mode.USER_CONTROLLED:
			if player_node.global_position.distance_to(player_start_pos) > 10.0:
				start_combat()

func _on_cinematic_cinematic_finished() -> void:
	start_combat()

func start_combat() -> void:
	if combat_started: 
		return
		
	combat_started = true
	print("¡Iniciando el Combate!")
	_start_wave()

# --- LÓGICA DE OLEADAS ---
func _start_wave() -> void:
	enemies_defeated_in_current_wave = 0
	print("--- INICIANDO OLEADA ", current_wave, " ---")
	
	# Llama al grupo de la oleada actual (wave_1, wave_2, wave_3)
	var wave_group_name = "wave_" + str(current_wave)
	get_tree().call_group(wave_group_name, "activate_rift")

func on_enemy_defeated() -> void:
	enemies_defeated_in_current_wave += 1
	var target_for_this_wave = enemies_per_wave[current_wave - 1]
	
	if enemies_defeated_in_current_wave >= target_for_this_wave:
		if current_wave < max_waves:
			current_wave += 1
			# Respiro de 1.5s antes de la siguiente oleada
			await get_tree().create_timer(1.5).timeout
			_start_wave()
		else:
			print("¡Arena Superada! Aparece el hilo coleccionable.")
			# --- MOSTRAR EL HILO PARA GANAR ---
			if collectible_node:
				collectible_node.show()
				collectible_node.process_mode = Node.PROCESS_MODE_INHERIT
				
				# ¡MAGIA!: Teletransportamos el hilo justo encima del jugador
				# Vector2(0, -40) hace que aparezca un poquito más arriba de su cabeza
				if is_instance_valid(player_node):
					collectible_node.global_position = player_node.global_position + Vector2(0, -40)

func damage_player() -> void:
	if is_player_invulnerable:
		return
	is_player_invulnerable = true
		
	player_hp -= 1
	print("¡Auch! Vida restante: ", player_hp)
	
	if player_hp <= 0:
		if player_node and player_node.has_method("defeat"):
			print("¡Jugador derrotado! Recargando escena...")
			player_node.defeat()
	else:
		if player_node:
			player_node.modulate = Color.RED
			await get_tree().create_timer(0.2).timeout
			player_node.modulate = Color.WHITE
			
		await get_tree().create_timer(0.8).timeout
		is_player_invulnerable = false
