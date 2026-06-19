extends Node2D

const UI_NODES_TO_HIDE: Array[String] = ["AimInputHint", "ThrowInputHint"]
var _hidden_ui_nodes: Array[CanvasItem] = []

var combat_started: bool = false
var player_node: CharacterBody2D = null
var boss_node: Area2D = null
var player_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	var found_player: Node = find_child("Player", true, false)
	if found_player and found_player is CharacterBody2D:
		player_node = found_player as CharacterBody2D
		player_start_pos = player_node.global_position
		
	var found_boss: Node = find_child("boss", true, false)
	if found_boss and found_boss is Area2D:
		boss_node = found_boss as Area2D

	_set_stealth_environment(true)

func _exit_tree() -> void:
	_set_stealth_environment(false)

func _process(_delta: float) -> void:
	if not combat_started and is_instance_valid(player_node) and is_instance_valid(boss_node):
		if player_node.mode == 0: 
			if player_node.global_position.distance_to(player_start_pos) > 10.0:
				start_combat()

func start_combat() -> void:
	combat_started = true
	if boss_node.has_method("iniciar_combate"):
		boss_node.iniciar_combate()

func _set_stealth_environment(active: bool) -> void:
	if active:
		var root: Window = get_tree().root
		for node_name: String in UI_NODES_TO_HIDE:
			var node: Node = root.find_child(node_name, true, false)
			if is_instance_valid(node) and node is CanvasItem:
				node.visible = false
				_hidden_ui_nodes.append(node)
	else:
		for node: CanvasItem in _hidden_ui_nodes:
			if is_instance_valid(node): 
				node.visible = true
		_hidden_ui_nodes.clear()

	if not is_instance_valid(player_node): 
		return
	
	if active:
		var hook: Node2D = player_node.get("player_hook") as Node2D
		if is_instance_valid(hook):
			hook.process_mode = Node.PROCESS_MODE_DISABLED
			hook.visible = false
	elif player_node.has_method("_toggle_abilities"):
		player_node.call("_toggle_abilities")
