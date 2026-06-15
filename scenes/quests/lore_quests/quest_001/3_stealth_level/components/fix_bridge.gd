# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const BRIDGE_TILESET_SOURCE_ID = 3
const FIXED_BRIDGE_ATLAS_COORDS = Vector2i(0, 2)

var _tiles_to_fix: Array[Vector2i] = [Vector2i(86, 21), Vector2i(108, 19)]

@onready var bridges: TileMapLayer = $"../../TileMapLayers/Bridges"


func fix_bridge() -> void:
	for t in _tiles_to_fix:
		bridges.set_cell(t, BRIDGE_TILESET_SOURCE_ID, FIXED_BRIDGE_ATLAS_COORDS)
	await get_tree().create_timer(1).timeout
