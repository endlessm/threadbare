# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ReplaceTeleporterNodesWithSceneInstances
extends EditorScript

const Util = preload("./util.gd")
const TELEPORTER_GD_UID := "uid://hqdquinbimce"
const TELEPORTER_SCENE: PackedScene = preload(
	"res://scenes/game_elements/props/teleporter/teleporter.tscn"
)


func _examine(packed_scene: PackedScene) -> void:
	var scene_state := packed_scene.get_state()
	var scene_root := packed_scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)

	for node_idx: int in scene_state.get_node_count():
		var path := scene_state.get_node_path(node_idx)

		var found := false
		for prop_idx: int in scene_state.get_node_property_count(node_idx):
			var prop_name := scene_state.get_node_property_name(node_idx, prop_idx)
			var prop_value: Variant = scene_state.get_node_property_value(node_idx, prop_idx)
			if prop_name == "metadata/_custom_type_script" and prop_value == TELEPORTER_GD_UID:
				found = true
				break
			elif prop_name == "script" and ResourceUID.path_to_uid((prop_value as Script).resource_path) == TELEPORTER_GD_UID:
				found = true
				break

		if not found:
			continue

		var orig: Node = scene_root.get_node(path)
		var replacement: Node = TELEPORTER_SCENE.instantiate(
			PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE
		)
		orig.replace_by(replacement)

		replacement.name = orig.name
		replacement.scene_file_path = TELEPORTER_SCENE.resource_path
		replacement.owner = scene_root

		for prop_idx: int in scene_state.get_node_property_count(node_idx):
			var prop_name := scene_state.get_node_property_name(node_idx, prop_idx)
			var prop_value: Variant = scene_state.get_node_property_value(node_idx, prop_idx)

			if prop_name not in ["metadata/_custom_type_script", "script"]:
				replacement.set(prop_name, prop_value)

		orig.free()

	var result := packed_scene.pack(scene_root)
	assert(result == OK, error_string(result))

	result = ResourceSaver.save(packed_scene)
	assert(result == OK, error_string(result))


func _should_check(scene_path: String) -> bool:
	if scene_path == TELEPORTER_SCENE.resource_path:
		return false

	for dependency in ResourceLoader.get_dependencies(scene_path):
		if dependency.contains("::"):
			var uid := dependency.get_slice("::", 0)
			if uid == TELEPORTER_GD_UID:
				return true

	return false


func _run() -> void:
	for scene: PackedScene in Util.find_scenes("res://", _should_check):
		print(scene.resource_path)
		_examine(scene)
