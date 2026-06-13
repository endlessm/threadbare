# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Toggleable
## Swaps tiles when toggled. Useful to fix a bridge if a quest is complete.

@export var tile_map_layer: TileMapLayer
@export var source_id: int = 3
## Map of atlas coordinates, from broken tile to fixed tile.
@export var broken_to_fixed_map: Dictionary[Vector2i, Vector2i] = {
	Vector2i(1, 3): Vector2i(0, 2),
	Vector2i(2, 2): Vector2i(1, 0),
}

# Map from atlas coordinate (keys of dict above) to array of cell coord
var _toggle_cells: Dictionary[Vector2i, Array]


func _ready() -> void:
	for broken_tile_atlas_coord: Vector2i in broken_to_fixed_map:
		var a: Array = tile_map_layer.get_used_cells_by_id(source_id, broken_tile_atlas_coord)
		_toggle_cells[broken_tile_atlas_coord] = a


func set_toggled(satisfied: bool) -> void:
	for broken: Vector2i in broken_to_fixed_map:
		var fixed := broken_to_fixed_map[broken]
		var new_tile := fixed if satisfied else broken
		for cell_coord: Vector2i in _toggle_cells[broken]:
			tile_map_layer.set_cell(cell_coord, source_id, new_tile)
