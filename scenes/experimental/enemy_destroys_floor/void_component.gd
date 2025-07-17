# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name VoidComponent  # TODO: better naem
extends Node2D

const _DURATION: float = 0.25

@export var void_layer: TileMapLayer
@export var consumable_node_holders: Array[Node]

var _unconsumed_nodes: Dictionary[Vector2i, Array] = {}
var _consumed_nodes: Dictionary[Vector2i, Array] = {}


func _ready() -> void:
	for parent: Node in consumable_node_holders:
		for child: Node in parent.get_children():
			if child is Node2D:
				var coord := void_layer.local_to_map(void_layer.to_local(child.global_position))
				var nodes: Array = _unconsumed_nodes.get_or_add(coord, [])
				assert(child not in nodes)
				nodes.append(child)


static func _hide_consumed(node: Node2D) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED


func consume(coord: Vector2i) -> void:
	if coord not in _unconsumed_nodes:
		return

	var nodes: Array = _unconsumed_nodes[coord]
	for node: Node2D in nodes:
		var tween := create_tween()
		# TODO: store previous modulate.a to restore in restore()
		tween.tween_property(node, "modulate:a", 0.0, _DURATION).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_hide_consumed.bind(node), CONNECT_ONE_SHOT)

	_consumed_nodes[coord] = nodes
	_unconsumed_nodes.erase(coord)


func restore(coord: Vector2i) -> void:
	if coord not in _consumed_nodes:
		return

	var nodes: Array = _consumed_nodes.get(coord)
	for node: Node2D in nodes:
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", 1.0, _DURATION)

	_unconsumed_nodes[coord] = nodes
	_consumed_nodes.erase(coord)
