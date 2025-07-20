# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name TileMapCover  # TODO: better naem
extends Node2D

const _DURATION: float = 0.25

@export var layer: TileMapLayer

@export var terrain_set: int
@export var terrain_name: String
## Nodes whose direct children (but not grandchildren) can be consumed.
@export var consumable_node_holders: Array[Node]

var _unconsumed_nodes: Dictionary[Vector2i, Array] = {}
var _consumed_nodes: Dictionary[Vector2i, Array] = {}

var _terrain_id: int = -1


func _find_terrain_id() -> void:
	assert(layer.tile_set)
	assert(layer.tile_set.get_terrain_sets_count() > terrain_set)
	for index: int in range(0, layer.tile_set.get_terrains_count(terrain_set)):
		var name: String = layer.tile_set.get_terrain_name(terrain_set, index)
		if name == terrain_name:
			_terrain_id = index
			break
	assert(_terrain_id >= 0)


func _ready() -> void:
	_find_terrain_id()

	for parent: Node in consumable_node_holders:
		for child: Node in parent.get_children():
			if child is Node2D:
				var coord := layer.local_to_map(layer.to_local(child.global_position))
				var nodes: Array = _unconsumed_nodes.get_or_add(coord, [])
				assert(child not in nodes)
				nodes.append(child)


func consume_cells(cells: Array[Vector2i], immediate: bool = false) -> void:
	for i in range(cells.size() - 1, -1, -1):
		var c: Vector2i = cells[i]

		if layer.get_cell_source_id(c) != -1:
			cells.remove_at(i)
			continue

	if cells:
		layer.set_cells_terrain_connect(cells, terrain_set, _terrain_id)

		for cell in cells:
			consume(cell, immediate)


func consume(coord: Vector2i, immediate: bool = false) -> void:
	if coord not in _unconsumed_nodes:
		return

	var nodes: Array = _unconsumed_nodes[coord]
	_unconsumed_nodes.erase(coord)
	# TODO: store previous modulate.a to restore in restore()
	if immediate:
		for node: Node2D in nodes:
			node.modulate.a = 0.0
	else:
		var tween := create_tween().set_parallel(true)
		for node: Node2D in nodes:
			tween.tween_property(node, "modulate:a", 0.0, _DURATION).set_ease(Tween.EASE_OUT)
		await tween.finished

	for node in nodes:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	_consumed_nodes[coord] = nodes


func restore_cells(cells: Array[Vector2i], immediate: bool = false) -> void:
	for i in range(cells.size() - 1, -1, -1):
		var c: Vector2i = cells[i]

		if layer.get_cell_source_id(c) == -1:
			cells.remove_at(i)
			continue

	if cells:
		layer.set_cells_terrain_connect(cells, terrain_set, -1)

		for cell in cells:
			restore(cell, immediate)


func restore(coord: Vector2i, _immediate: bool) -> void:
	if coord not in _consumed_nodes:
		return

	var nodes: Array = _consumed_nodes.get(coord)
	for node: Node2D in nodes:
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", 1.0, _DURATION)

	_unconsumed_nodes[coord] = nodes
	_consumed_nodes.erase(coord)
