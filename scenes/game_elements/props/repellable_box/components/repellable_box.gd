# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatableBody2D

const NEIGHBORS_FOR_AXIS: Dictionary[Vector2i, TileSet.CellNeighbor] = {
	Vector2i.DOWN: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	Vector2i.LEFT: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	Vector2i.UP: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	Vector2i.RIGHT: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
}

@export var constrain_layer: TileMapLayer

var tween: Tween

@onready var shaker: Shaker = $Shaker


func global_position_to_tile_coordinate(global_pos: Vector2) -> Vector2i:
	return constrain_layer.local_to_map(constrain_layer.to_local(global_pos))


func tile_coordinate_to_global_position(coord: Vector2i) -> Vector2:
	return constrain_layer.map_to_local(coord)


func _ready() -> void:
	# Put this object on the grid:
	var coord := global_position_to_tile_coordinate(global_position)
	global_position = tile_coordinate_to_global_position(coord)


func get_closest_axis(vector: Vector2) -> Vector2i:
	if abs(vector.x) > abs(vector.y):
		# Closer to Horizontal (X-axis)
		return Vector2i(sign(vector.x), 0)

	# Closer to Vertical (Y-axis)
	return Vector2i(0, sign(vector.y))


func got_repelled(direction: Vector2) -> void:
	var axis := get_closest_axis(direction)
	if axis == Vector2i.ZERO:
		shaker.shake()
		return

	var neighbor := NEIGHBORS_FOR_AXIS[axis]
	var coord := global_position_to_tile_coordinate(global_position)
	assert(constrain_layer.get_cell_tile_data(coord) != null)
	var new_coord := constrain_layer.get_neighbor_cell(coord, neighbor)
	var data := constrain_layer.get_cell_tile_data(new_coord)

	if not data:
		shaker.shake()
		return

	if tween:
		if tween.is_running():
			return
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	# Assuming that the tile size is square:
	var new_position := position + Vector2(axis) * constrain_layer.tile_set.tile_size.x
	tween.tween_property(self, "position", new_position, .2)
