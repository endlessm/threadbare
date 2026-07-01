extends Node2D

@export var player: CharacterBody2D
@export var push_force: float = 150.0

const UI_NODES_TO_HIDE: Array[String] = ["AimInputHint", "ThrowInputHint", "RepelInputHint"]
var _hidden_ui_nodes: Array[CanvasItem] = []

func _ready() -> void:
	_set_stealth_environment(true)

func _exit_tree() -> void:
	_set_stealth_environment(false)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): return
	
	# Colisiones para objetos interactuables
	for i in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if collider is RigidBody2D and collider.is_in_group("pushable"):
			collider.apply_central_impulse(-collision.get_normal() * push_force)

# Gestiona la UI global y anula componentes de combate localmente
func _set_stealth_environment(active: bool) -> void:
	# Manejo de UI Hints
	if active:
		var root: Window = get_tree().root
		for node_name in UI_NODES_TO_HIDE:
			var node: Node = root.find_child(node_name, true, false)
			if is_instance_valid(node) and node is CanvasItem:
				node.visible = false
				_hidden_ui_nodes.append(node)
	else:
		for node in _hidden_ui_nodes:
			if is_instance_valid(node): node.visible = true
		_hidden_ui_nodes.clear()

	# Manejo de habilidades del jugador
	if not is_instance_valid(player): return
	
	if active:
		for component: String in ["player_hook", "player_repel"]:
			var node: Node2D = player.get(component) as Node2D
			if is_instance_valid(node):
				node.process_mode = Node.PROCESS_MODE_DISABLED
				node.visible = false
	elif player.has_method("_toggle_abilities"):
		player.call("_toggle_abilities")
