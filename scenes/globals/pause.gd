# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal pause_changed(system: System, paused: bool)

enum System {
	PLAYER_INPUT,
	GAME,
}

var _pause_requests: Dictionary[System, Array] = {
	System.PLAYER_INPUT: [],
	System.GAME: [],
}


func pause_system(system: System, node: Node) -> void:
	if _pause_requests[system].has(node):
		print(
			(
				"Node %s requested pause for system %s but already exists"
				% [node.name, System.find_key(system)]
			)
		)
		return

	if _pause_requests[system].is_empty():
		# This is the first node pausing the system, so we emit the signal.
		pause_changed.emit(system, true)

	_pause_requests[system].push_back(node)
	node.tree_exited.connect(self._remove_pauses_of_node.bind(node), CONNECT_ONE_SHOT)


func unpause_system(system: System, node: Node) -> void:
	if not _pause_requests[system].has(node):
		return
	_pause_requests[system].erase(node)
	node.tree_exited.disconnect(self._remove_pauses_of_node.bind(system, node))

	if _pause_requests[system].is_empty():
		# This was the last node pausing the system, so we emit the signal.
		pause_changed.emit(system, false)


func is_paused(system: System) -> bool:
	return not _pause_requests[system].is_empty()


func _ready() -> void:
	pause_changed.connect(_on_pause_changed)


func _on_pause_changed(system: System, paused: bool) -> void:
	if not is_inside_tree():
		# This can happen when the game is quitting.
		return

	match system:
		System.GAME:
			get_tree().paused = paused


func _remove_pauses_of_node(removed_node: Node) -> void:
	for nodes_pausing: Array in _pause_requests.values():
		nodes_pausing.erase(removed_node)
	for system in _pause_requests:
		if not _pause_requests[system].is_empty():
			continue
		# No more nodes pausing the system, so we emit the signal.
		pause_changed.emit(system, false)
