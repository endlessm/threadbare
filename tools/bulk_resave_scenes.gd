# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BulkResaveScenes
extends EditorScript
## Loads and saves all scenes which depend on particular resource(s)
##
## Edit [const DEPENDENCIES] then run this in the editor.
## [br][br]
## This can be useful when the dependency has code that adjusts the scene (or
## itself) when opened in the editor. You can also use Project -> Tools ->
## Upgrade Project Files... but that saves every scene in the project and takes
## ages.

const Util = preload("./util.gd")
const DEPENDENCIES := [
	"res://scenes/game_elements/props/collectible_item/collectible_item.tscn",
]


func _matches(scene_path: String) -> bool:
	for dependency: String in ResourceLoader.get_dependencies(scene_path):
		var path := dependency.get_slice("::", 2) if dependency.contains("::") else dependency
		if path in DEPENDENCIES:
			return true

	return false


func resave(ps: PackedScene) -> void:
	var root_node := ps.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	var result := ps.pack(root_node)
	if result == OK:
		result = ResourceSaver.save(ps)
		if result != OK:
			prints("failed to save", ps, result)
	else:
		prints("failed to pack", ps, result)
	root_node.queue_free()


func _run() -> void:
	for ps: PackedScene in Util.find_scenes("res://scenes/quests", _matches):
		prints("-", ps.resource_path)
		resave(ps)
