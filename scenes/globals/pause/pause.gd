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


func _ready() -> void:
	pause_changed.connect(_on_pause_changed)


func _on_pause_changed(system: System, paused: bool) -> void:
	if not is_inside_tree():
		# This can happen when the game is quitting.
		return

	match system:
		System.GAME:
			get_tree().paused = paused


func pause_system(system: System, node: Node) -> void:
	var nodes_pausing: Array = _pause_requests[system]

	if nodes_pausing.has(node):
		print(
			(
				"Node %s requested pause for system %s but already exists"
				% [node.name, System.find_key(system)]
			)
		)

		return

	var was_paused: bool = is_paused(system)

	nodes_pausing.push_back(node)
	node.tree_exited.connect(self._remove_pauses_of_node.bind(node), CONNECT_ONE_SHOT)

	if not was_paused:
		pause_changed.emit(system, true)


func unpause_system(system: System, node: Node) -> void:
	var nodes_pausing: Array = _pause_requests[system]

	if nodes_pausing.has(node):
		node.tree_exited.disconnect(self._remove_pauses_of_node.bind(system, node))

		nodes_pausing.erase(node)

		if nodes_pausing.is_empty():
			pause_changed.emit(system, false)


func is_paused(system: System) -> bool:
	return not _pause_requests[system].is_empty()


func _remove_pauses_of_node(removed_node: Node) -> void:
	for system: System in _pause_requests.keys():
		var nodes_pausing: Array = _pause_requests[system]

		if nodes_pausing.has(removed_node):
			nodes_pausing.erase(removed_node)

			if nodes_pausing.is_empty():
				pause_changed.emit(system, false)
