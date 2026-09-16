# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

@tool
class_name Elephant
extends EditorScript

const ELEVATION_TILESET_PATH = "res://tiles/elevation_2.tres"
const SOURCE_ID := 0
const WALLS := 0


func _run() -> void:
	var tiles := load(ELEVATION_TILESET_PATH) as TileSet
	var source := tiles.get_source(SOURCE_ID) as TileSetAtlasSource
	for i: int in source.get_tiles_count():
		var coords := source.get_tile_id(i)
		var tile_data := source.get_tile_data(coords, 0)

		# Don't create alts for stairs
		if tile_data.get_collision_polygons_count(WALLS) == 0:
			continue

		if not source.has_alternative_tile(coords, 1):
			var alt_id := source.create_alternative_tile(coords, 1)
			if alt_id != 1:
				prints("oh no", coords, alt_id)

		var alt_tile_data := source.get_tile_data(coords, 1)

		# Duplicate all properties from the base tile as a baseline
		for x in tile_data.get_property_list():
			alt_tile_data.set(x["name"], tile_data.get(x["name"]))

		# Remove wall collisions
		alt_tile_data.set_collision_polygons_count(WALLS, 0)

		# Don't place it when drawing random tiles or terrains
		alt_tile_data.probability = 0.0

		alt_tile_data.modulate = Color.RED  # TODO: remove this

	ResourceSaver.save(tiles)
