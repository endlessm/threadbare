extends Node

enum System {
	PLAYER_INPUT,
	GAME
	# For now is just these two but in the future we could have: Physics, Enemies, AI, etc
}

# Private vars
var _pause_requests: Dictionary[System, Array] = {}

# This should be an array of systems but it throws
# a runtime error when using the filter function, so for now just "Array"
var _paused_systems: Array = []


# Public interface
func pause_system(system: System, node: Node) -> void:
	_add_request(system, node)


func unpause_system(system: System, node: Node) -> void:
	_clear_request(system, node)

	_refresh_systems()


func is_paused(system: System) -> bool:
	return system in paused_systems()


func paused_systems() -> Array:
	return _paused_systems


# Private methods
func _exists_request_for_system(a_system: System) -> bool:
	return !_pause_requests.get_or_add(a_system, []).is_empty()


func _add_request(system: System, a_node: Node) -> void:
	var nodes_pausing: Array = _pause_requests.get_or_add(system, [])

	if !nodes_pausing.has(a_node):
		nodes_pausing.push_back(a_node)
		a_node.tree_exited.connect(self._remove_pauses_of_node.bind(a_node), CONNECT_ONE_SHOT)

		_refresh_systems()
	else:
		print(
			(
				"Node %s requested pause for system %s but already exists"
				% [a_node.name, System.find_key(system)]
			)
		)


func _clear_request(system: System, a_node: Node) -> void:
	var nodes_pausing: Array = _pause_requests.get_or_add(system, [])

	if nodes_pausing.has(a_node):
		nodes_pausing.erase(a_node)
		a_node.tree_exited.disconnect(self._remove_pauses_of_node.bind(system, a_node))

		_refresh_systems()


func _refresh_systems() -> void:
	_refresh_paused_systems()

	if not is_inside_tree():
		# This can happen when the game is quitting
		return

	if is_paused(System.GAME):
		get_tree().paused = true
	else:
		get_tree().paused = false


func _refresh_paused_systems() -> void:
	_paused_systems = System.values().filter(
		func(system: System) -> bool: return _exists_request_for_system(system)
	)


func _remove_pauses_of_node(removed_node: Node) -> void:
	for nodes_pausing: Array in _pause_requests.values():
		nodes_pausing.erase(removed_node)

	_refresh_systems()
