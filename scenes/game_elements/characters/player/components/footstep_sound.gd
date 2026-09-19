# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var sound_for_material: Dictionary[String, AudioStream]

var _footstep_layers: Array[TileMapLayer] = []

@onready var walk_sound: AudioStreamPlayer2D = %WalkSound

var _default_walk_sound: AudioStream

## Stores the default footstep sound and caches TileMapLayers whose TileSets
## define a "material" custom data layer.
func _ready() -> void:
	_default_walk_sound = walk_sound.stream

	var scene_root := get_tree().current_scene
	var tile_map_layers := scene_root.find_children("*", "TileMapLayer", true, false)

	for node in tile_map_layers:
		var layer := node as TileMapLayer
		if not layer:
			continue

		if not layer.tile_set:
			continue

		if not layer.tile_set.has_custom_data_layer_by_name("material"):
			continue

		_footstep_layers.append(layer)


## Detects the terrain material beneath the player and plays its configured
## footstep sound. Falls back to the default sound when no match is configured.
## Called from the footstep frames defined in the walk animation.
func play_footstep() -> void:
	if Engine.is_editor_hint():
		return

	var current_footstep_material: String = ""

	for layer in _footstep_layers:
		var coord := layer.local_to_map(
			layer.to_local(global_position)
		)
		var tile_data := layer.get_cell_tile_data(coord)

		if not tile_data:
			continue

		var footstep_material: Variant = tile_data.get_custom_data("material")
		if footstep_material is String and not footstep_material.is_empty():
			current_footstep_material = footstep_material

	var footstep_sound: AudioStream = sound_for_material.get(
		current_footstep_material,
		_default_walk_sound
	)

	walk_sound.stream = footstep_sound
	walk_sound.play()
