# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name TileMapCover  # TODO: better naem
extends TileMapLayer

const _DURATION: float = 0.25

## The terrain set that contains the terrain that covers the world.
@export_range(0, 50) var terrain_set: int = 0:
	set = _set_terrain_set

## The name of the terrain set which covers the world.
@export var terrain_name: String = "VoidChromakey":
	set = _set_terrain_name

## Nodes whose direct children (but not grandchildren) can be consumed.
@export var consumable_node_holders: Array[Node]

var _unconsumed_nodes: Dictionary[Vector2i, Array] = {}
var _consumed_nodes: Dictionary[Vector2i, Array] = {}

var _terrain_id: int = -1


func _set_terrain_set(new_value: int) -> void:
	terrain_set = new_value
	update_configuration_warnings()
	notify_property_list_changed()


func _set_terrain_name(new_value: String) -> void:
	terrain_name = new_value
	_update_terrain_id()
	update_configuration_warnings()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"terrain_set":
			if tile_set and tile_set.get_terrain_sets_count() > 0:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(range(tile_set.get_terrain_sets_count()).map(str))

		"terrain_name":
			if tile_set and 0 <= terrain_set and terrain_set < tile_set.get_terrain_sets_count():
				var names: Array[String]
				for i: int in range(0, tile_set.get_terrains_count(terrain_set)):
					names.append(tile_set.get_terrain_name(terrain_set, i))
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(names)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not tile_set:
		warnings.append("Tile set is not set")
	elif terrain_set < 0 or terrain_set >= tile_set.get_terrain_sets_count():
		warnings.append("Terrain set ID out of range")
	elif terrain_name == "":
		warnings.append("Terrain name unset")
	elif _terrain_id < 0:
		warnings.append("Terrain %s not found" % terrain_name)

	return warnings


func _update_terrain_id() -> void:
	_terrain_id = -1
	if not tile_set:
		return

	if 0 > terrain_set or terrain_set >= tile_set.get_terrain_sets_count():
		return

	for index: int in range(0, tile_set.get_terrains_count(terrain_set)):
		var name: String = tile_set.get_terrain_name(terrain_set, index)
		if name == terrain_name:
			_terrain_id = index
			return


func coord_for(node: Node2D) -> Vector2i:
	return local_to_map(to_local(node.global_position))


func _ready() -> void:
	_update_terrain_id()

	for parent: Node in consumable_node_holders:
		for child: Node in parent.get_children():
			if child is Node2D:
				var coord := coord_for(child)
				var nodes: Array = _unconsumed_nodes.get_or_add(coord, [])
				assert(child not in nodes)
				nodes.append(child)


func consume_cells(cells: Array[Vector2i], immediate: bool = false) -> void:
	for i in range(cells.size() - 1, -1, -1):
		var c: Vector2i = cells[i]

		if get_cell_source_id(c) != -1:
			cells.remove_at(i)
			continue

	if cells:
		set_cells_terrain_connect(cells, terrain_set, _terrain_id)

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

		if get_cell_source_id(c) == -1:
			cells.remove_at(i)
			continue

	if cells:
		set_cells_terrain_connect(cells, terrain_set, -1)

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
