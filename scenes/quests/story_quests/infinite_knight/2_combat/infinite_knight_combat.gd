extends Node2D

var player_hp: int = 3
var is_player_invulnerable: bool = false
var combat_started: bool = false

var player_start_pos: Vector2 = Vector2.ZERO
var player_node: CharacterBody2D = null

var _hidden_ui_nodes: Array[CanvasItem] = []

var current_wave: int = 1
var max_waves: int = 3
var enemies_defeated_in_current_wave: int = 0
var collectible_node: CollectibleItem = null

var enemies_per_wave: Array[int] = [3, 5, 7] 

func _ready() -> void:
	var found_player: Node = find_child("Player", true, false)
	if found_player and found_player is CharacterBody2D:
		player_node = found_player as CharacterBody2D
		player_start_pos = player_node.global_position
		player_node.set_collision_mask_value(3, true)
		
		var repel_node: Node = player_node.get_node_or_null("%PlayerRepel")
		if repel_node:
			repel_node.input_action = "attack" 
			if repel_node is CanvasItem:
				repel_node.hide()
				
	# Oculta el letrero de tutorial viejo sin destruirlo
	var root: Window = get_tree().root
	var viejo_letrero: CanvasItem = root.find_child("RepelInputHint", true, false) as CanvasItem
	if is_instance_valid(viejo_letrero):
		viejo_letrero.modulate.a = 0.0 
		_hidden_ui_nodes.append(viejo_letrero)
		
	# Oculta el hilo usando su propia variable para no romper sus fisicas
	var found_collectible: Node = find_child("CollectibleItem", true, false)
	if found_collectible and found_collectible is CollectibleItem:
		collectible_node = found_collectible as CollectibleItem
		collectible_node.revealed = false

func _exit_tree() -> void:
	for node in _hidden_ui_nodes:
		if is_instance_valid(node): 
			node.modulate.a = 1.0
	_hidden_ui_nodes.clear()

func _process(_delta: float) -> void:
	if not combat_started and is_instance_valid(player_node):
		if player_node.mode == Player.Mode.USER_CONTROLLED:
			if player_node.global_position.distance_to(player_start_pos) > 10.0:
				start_combat()

func _on_cinematic_cinematic_finished() -> void:
	start_combat()

func start_combat() -> void:
	if combat_started: 
		return
	combat_started = true
	_start_wave()

func _start_wave() -> void:
	enemies_defeated_in_current_wave = 0
	var wave_group_name: String = "wave_" + str(current_wave)
	get_tree().call_group(wave_group_name, "activate_rift")

func on_enemy_defeated() -> void:
	enemies_defeated_in_current_wave += 1
	var target_for_this_wave: int = enemies_per_wave[current_wave - 1]
	
	if enemies_defeated_in_current_wave >= target_for_this_wave:
		if current_wave < max_waves:
			current_wave += 1
			await get_tree().create_timer(1.5).timeout
			_start_wave()
		else:
			# Victoria: Muestra el hilo arriba del jugador
			if is_instance_valid(collectible_node):
				if is_instance_valid(player_node):
					collectible_node.global_position = player_node.global_position + Vector2(0, -40)
				
				collectible_node.set_deferred("revealed", true)
				if collectible_node.has_method("reveal"):
					collectible_node.call_deferred("reveal")

func damage_player() -> void:
	if is_player_invulnerable: 
		return
		
	is_player_invulnerable = true
	player_hp -= 1
	
	if player_hp <= 0:
		if is_instance_valid(player_node) and player_node.has_method("defeat"):
			player_node.defeat()
	else:
		if is_instance_valid(player_node):
			player_node.modulate = Color.RED
			await get_tree().create_timer(0.2).timeout
			if is_instance_valid(player_node):
				player_node.modulate = Color.WHITE
		
		await get_tree().create_timer(0.8).timeout
		is_player_invulnerable = false
