# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorScript

const OLD_TILESET := preload("res://scenes/tileset.tres")

const NEW_TILESETS := {
	[0]: preload("res://tiles/water.tres"),
	[1, 5, 6]: preload("res://tiles/exterior_floors.tres"),
	[2]: preload("res://tiles/foam.tres"),
	[3]: preload("res://tiles/bridges.tres"),
	[4, 7]: preload("res://tiles/elevation.tres"),
	[13]: preload("res://tiles/void_chromakey.tres"),
}

const SCENES := [
	"scenes/game_elements/characters/components/gym_area_test.tscn",
	"scenes/game_elements/props/area_filler/components/area_filler_test.tscn",
	"scenes/game_elements/props/void/components/void_chromakey_test.tscn",
	"scenes/quests/lore_quests/quest_001/1_music_puzzle/music_puzzle.tscn",
	"scenes/quests/lore_quests/quest_001/2_ink_combat/ink_combat_round_1.tscn",
	"scenes/quests/lore_quests/quest_001/2_ink_combat/ink_combat_round_2.tscn",
	"scenes/quests/lore_quests/quest_001/2_ink_combat/ink_combat_round_3.tscn",
	"scenes/quests/lore_quests/quest_001/3_stealth_level/stealth_level.tscn",
	"scenes/quests/lore_quests/quest_001/4_closing_transition/closing_transition.tscn",
	"scenes/quests/lore_quests/quest_002/1_void_runner/void_runner.tscn",
	"scenes/quests/lore_quests/quest_002/2_grappling_hook/grappling_hook_end.tscn",
	"scenes/quests/lore_quests/quest_002/2_grappling_hook/grappling_hook_needles.tscn",
	"scenes/quests/lore_quests/quest_002/2_grappling_hook/grappling_hook_pins.tscn",
	"scenes/quests/lore_quests/quest_002/2_grappling_hook/grappling_hook_powerup.tscn",
	"scenes/quests/lore_quests/quest_002/2_grappling_hook/grappling_hook_start.tscn",
	"scenes/quests/lore_quests/quest_002/3_void_grappling/void_grappling.tscn",
	"scenes/quests/story_quests/NO_EDIT/0_NO_EDIT_intro/NO_EDIT_intro.tscn",
	"scenes/quests/story_quests/NO_EDIT/1_NO_EDIT_stealth/NO_EDIT_stealth.tscn",
	"scenes/quests/story_quests/NO_EDIT/2_NO_EDIT_combat/NO_EDIT_combat.tscn",
	"scenes/quests/story_quests/NO_EDIT/3_NO_EDIT_sequence_puzzle/NO_EDIT_sequence_puzzle.tscn",
	"scenes/quests/story_quests/NO_EDIT/4_NO_EDIT_outro/NO_EDIT_outro.tscn",
	"scenes/quests/story_quests/el_juguete_perdido/0_intro/intro.tscn",
	"scenes/quests/story_quests/el_juguete_perdido/1_stealth/stealth.tscn",
	"scenes/quests/story_quests/el_juguete_perdido/2_combat/combat.tscn",
	"scenes/quests/story_quests/el_juguete_perdido/3_sequence_puzzle/sequence_puzzle.tscn",
	"scenes/quests/story_quests/el_juguete_perdido/4_outro/outro.tscn",
	"scenes/quests/story_quests/stella/0_stella_intro/stella_intro.tscn",
	"scenes/quests/story_quests/stella/1_stella_stealth/stella_stealth.tscn",
	"scenes/quests/story_quests/stella/2_stella_combat/stella_combat.tscn",
	"scenes/quests/story_quests/stella/3_stella_sequence_puzzle/stella_sequence_puzzle.tscn",
	"scenes/quests/story_quests/stella/4_stella_outro/stella_outro.tscn",
	"scenes/quests/story_quests/verso/2_verso_stealth_sadness/verso_stealth.tscn",
	"scenes/quests/story_quests/verso/4_verso_outro/verso_outro.tscn",
	"scenes/world_map/frays_end.tscn",
]


func is_subset(a: Array, b: Array) -> bool:
	for x in a:
		if x not in b:
			return false

	return true


func _run() -> void:
	var source_id_users: Array
	for scene_path: String in SCENES:
		var packed_scene: PackedScene = load(scene_path)
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

			if not used_source_ids:
				prints(scene_path, tml.name, "is empty")
				continue

			var matches_new_tileset := false
			for source_id_group: Array in NEW_TILESETS.keys():
				if is_subset(used_source_ids, source_id_group):
					var new_tileset: TileSet = NEW_TILESETS[source_id_group]
					tml.tile_set = new_tileset
					matches_new_tileset = true
					scene_changed = true
					break

			if not matches_new_tileset:
				prints(scene_path, tml.name, "mixes:")
				for source_id in used_source_ids:
					var source := OLD_TILESET.get_source(source_id)
					var name: String = source.texture.resource_path.get_file()

					var cells := tml.get_used_cells_by_id(source_id)
					if cells:
						prints("  -", name, cells.slice(0, 5))

		if scene_changed:
			var result := packed_scene.pack(scene)
			if result == OK:
				result = ResourceSaver.save(packed_scene)
			if result != OK:
				push_error(error_string(result))
