# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

enum WaterAlternatives {
	UNSET = -1,
	NORMAL = 0,
	WALKABLE = 1,
	TOP_WALKABLE = 2,
}
enum FillMode {
	WHEN_EXPOSED,
	WHEN_NEIGHBOURS_EXPOSED,
}

const WATER_SOURCE_ID := 0
const WATER_TILE := Vector2i(0, 0)

const FOAM_SOURCE_ID := 2
const FOAM_TILE := Vector2i(0, 0)

const SHADOWS_SOURCE_ID = 0
const SHADOWS_TILE := Vector2i(0, 0)

const BRIDGES_SOURCE_ID = 3

@export var water: TileMapLayer
@export var foam: TileMapLayer
@export var floors: Array[TileMapLayer]

# TODO: array of pairs
@export var bridge_shadows: TileMapLayer
@export var bridges: Array[TileMapLayer]

# TODO: array of pairs
@export var elevation_shadows: TileMapLayer
@export var elevation: TileMapLayer

@export_tool_button("Update") var update: Callable = _update


func _non_water_layers() -> Array[TileMapLayer]:
	var xs := floors.duplicate()
	xs.append(elevation)
	return xs


func _update() -> void:
	_toggle(water, _non_water_layers(), [], FillMode.WHEN_EXPOSED, WATER_SOURCE_ID, WATER_TILE)
	_cliff_o_matic()

	_toggle(
		foam, _non_water_layers(), [], FillMode.WHEN_NEIGHBOURS_EXPOSED, FOAM_SOURCE_ID, FOAM_TILE
	)

	_toggle(
		elevation_shadows,
		[elevation],
		[Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)],
		FillMode.WHEN_NEIGHBOURS_EXPOSED,
		SHADOWS_SOURCE_ID,
		SHADOWS_TILE
	)

	_bridge_o_matic()

	if get_tree().edited_scene_root == owner:
		Engine.get_singleton("EditorInterface").mark_scene_as_unsaved()


func _get_layer_offset(layer: TileMapLayer) -> Vector2i:
	var default := 1 if layer == elevation else 0
	return Vector2i(0, 1) * (layer.get_meta(&"height", default) as int)


# Toggle tiles in [param lower] based on the presence or absence of tiles in
# [param upper_layers], taking into account the offset for each of those
# according to _get_layer_offset().
func _toggle(
	lower: TileMapLayer,
	upper_layers: Array[TileMapLayer],
	ignore_upper_tiles: Array[Vector2i],
	fill_mode: FillMode,
	source_id: int,
	atlas_coords: Vector2i,
	alternative_tile: int = 0
) -> void:
	var box := lower.get_used_rect()
	var upper_cells: Dictionary[Vector2i, bool]
	for layer: TileMapLayer in upper_layers:
		var offset := _get_layer_offset(layer)
		for used_cell: Vector2i in layer.get_used_cells():
			if not layer.get_cell_atlas_coords(used_cell) in ignore_upper_tiles:
				upper_cells[used_cell + offset] = true

		box = box.merge(layer.get_used_rect().grow(2))

	for x: int in range(box.position.x, box.end.x):
		for y: int in range(box.position.y, box.end.y):
			var coords := Vector2i(x, y)
			var covered := upper_cells.has(coords)
			var neighbours_covered := (
				upper_cells.has(coords + Vector2i.UP)
				and upper_cells.has(coords + Vector2i.DOWN)
				and upper_cells.has(coords + Vector2i.LEFT)
				and upper_cells.has(coords + Vector2i.RIGHT)
			)
			if (
				(fill_mode == FillMode.WHEN_EXPOSED and not covered)
				or (
					fill_mode == FillMode.WHEN_NEIGHBOURS_EXPOSED
					and covered
					and not neighbours_covered
				)
			):
				lower.set_cell(coords, source_id, atlas_coords, alternative_tile)
			else:
				lower.erase_cell(coords)


func _cliff_o_matic() -> void:
	for coords: Vector2i in elevation.get_used_cells():
		# Make water behind clifftops walkable
		if water.get_cell_source_id(coords) != -1:
			water.set_cell(coords, WATER_SOURCE_ID, WATER_TILE, WaterAlternatives.WALKABLE)

		# Make cliffs above stairs walkable
		if elevation.get_cell_atlas_coords(coords).y == 7:
			var up := coords + Vector2i.UP
			elevation.set_cell(
				up, elevation.get_cell_source_id(up), elevation.get_cell_atlas_coords(up), 1
			)


# Paint shadows below bridges.
func _bridge_o_matic() -> void:
	bridge_shadows.clear()

	for b: TileMapLayer in bridges:
		var offset := _get_layer_offset(b)
		for coords: Vector2i in b.get_used_cells():
			var bridge_atlas_coords := b.get_cell_atlas_coords(coords)
			var water_alt := WaterAlternatives.UNSET
			var elevation_alt := 0
			match bridge_atlas_coords:
				Vector2i(0, 0):  # Horizontal left anchor
					elevation_alt = 1
				Vector2i(1, 0):  # Horizontal bridge middle segment
					bridge_shadows.set_cell(coords + offset, BRIDGES_SOURCE_ID, Vector2i(2, 3))
					water_alt = WaterAlternatives.WALKABLE
					elevation_alt = 1
				Vector2i(2, 0):  # Horizontal right anchor
					elevation_alt = 1
				Vector2i(0, 1):  # Vertical bridge top
					elevation_alt = 1
				Vector2i(0, 2):  # Vertical bridge middle segment
					water_alt = WaterAlternatives.WALKABLE
					elevation_alt = 1
				Vector2i(0, 3):  # Bottom of vertical bridge
					water_alt = WaterAlternatives.TOP_WALKABLE
					# (TODO: and how about pontoons in other directions?!)
					elevation_alt = 1

			if water.get_cell_source_id(coords) != -1 and water_alt != WaterAlternatives.UNSET:
				water.set_cell(coords, WATER_SOURCE_ID, WATER_TILE, water_alt)

			if elevation.get_cell_alternative_tile(coords) == 0 and elevation_alt != 0:
				var source_id := elevation.get_cell_source_id(coords)
				var atlas_coords := elevation.get_cell_atlas_coords(coords)
				elevation.set_cell(coords, source_id, atlas_coords, elevation_alt)
