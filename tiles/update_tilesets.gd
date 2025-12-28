# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorScript
## Updates all scenes in the project tree that use the old unified tileset.
##
## This only works for TileMapLayer nodes that only use one group of
## TileSetAtlasSources from the old tileset. If a layer mixes different groups,
## a message is logged and that layer is skipped. Similarly, for empty layers a
## message is logged. A human can assign the correct TileSet.

const OLD_TILESET := preload("res://scenes/tileset.tres")

const WATER := preload("res://tiles/water.tres")
const EXTERIOR_FLOORS := preload("res://tiles/exterior_floors.tres")
const FOAM := preload("res://tiles/foam.tres")
const BRIDGES := preload("res://tiles/bridges.tres")
const ELEVATION := preload("res://tiles/elevation.tres")
const VOID := preload("res://tiles/void_chromakey.tres")

const NEW_TILESETS := {
	[0]: WATER,
	[1, 5, 6]: EXTERIOR_FLOORS,
	[2]: FOAM,
	[3]: BRIDGES,
	[4, 7]: ELEVATION,
	[13]: VOID,
}

const EMPTY_LAYER_MAPPINGS := {
	"TileMapLayer": null,  # empty dummy layer => delete
	"Stone": ELEVATION,
	"Cliffs": ELEVATION,
	"Grass": EXTERIOR_FLOORS,
	"Foam": FOAM,
	"Bridges": BRIDGES,
}


func is_subset(a: Array, b: Array) -> bool:
	for x in a:
		if x not in b:
			return false

	return true


## Find all scenes in the project tree that use OLD_TILESET.
func find_scenes() -> Array[PackedScene]:
	var packed_scenes: Array[PackedScene] = []
	var old_tileset_uid := ResourceUID.path_to_uid(OLD_TILESET.resource_path)
	var err: Error

	var dirs: Array[String] = ["res://"]
	while not dirs.is_empty():
		var current_dir: String = dirs.pop_back()
		var dir := DirAccess.open(current_dir)
		if not dir:
			err = dir.get_open_error()
			push_error("Failed to open", dir, ":", error_string(err))
			continue

		err = dir.list_dir_begin()
		if err != OK:
			push_error("Failed to list directory", dir, ":", error_string(err))
			continue

		var file_name = dir.get_next()
		while file_name != "":
			var path = current_dir.path_join(file_name)
			if dir.current_is_dir():
				dirs.push_back(path)
			elif file_name.ends_with(".tscn"):
				for dep: String in ResourceLoader.get_dependencies(path):
					if OLD_TILESET.resource_path in dep or old_tileset_uid in dep:
						var scene = load(path)
						if scene:
							packed_scenes.push_back(scene)
						break
			file_name = dir.get_next()
		dir.list_dir_end()

	return packed_scenes


func _run() -> void:
	for packed_scene: PackedScene in find_scenes():
		process_scene(packed_scene)


func update_tileset(
	packed_scene: PackedScene, tml: TileMapLayer, used_source_ids: Array[int]
) -> bool:
	if not used_source_ids:
		for pattern: String in EMPTY_LAYER_MAPPINGS:
			if pattern in tml.name:
				var new_tileset: TileSet = EMPTY_LAYER_MAPPINGS[pattern]
				prints(packed_scene.resource_path, tml.name, "is empty but matches", pattern)
				if new_tileset:
					tml.tile_set = new_tileset
				else:
					tml.get_parent().remove_child(tml)
					tml.queue_free()

				return true

		prints(packed_scene.resource_path, tml.name, "is empty")
		return false

	for source_id_group: Array in NEW_TILESETS.keys():
		if is_subset(used_source_ids, source_id_group):
			var new_tileset: TileSet = NEW_TILESETS[source_id_group]
			tml.tile_set = new_tileset
			return true

	prints(packed_scene.resource_path, tml.name, "mixes:")
	for source_id in used_source_ids:
		var source := OLD_TILESET.get_source(source_id)
		var name: String = source.texture.resource_path.get_file()

		var cells := tml.get_used_cells_by_id(source_id)
		if cells:
			prints("  -", name, cells.slice(0, 5))

	return false


func process_scene(packed_scene: PackedScene) -> void:
	var scene: Node = packed_scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	var scene_changed := false

	for tml: TileMapLayer in scene.find_children("", "TileMapLayer"):
		if tml.tile_set != OLD_TILESET:
			continue

		var used_source_ids: Array[int]

		for idx in range(OLD_TILESET.get_source_count()):
			var source_id := OLD_TILESET.get_source_id(idx)
			var cells := tml.get_used_cells_by_id(source_id)
			if cells:
				used_source_ids.append(source_id)

		if update_tileset(packed_scene, tml, used_source_ids):
			scene_changed = true

	if scene_changed:
		var result := packed_scene.pack(scene)
		if result == OK:
			result = ResourceSaver.save(packed_scene)
		if result != OK:
			push_error(error_string(result))
