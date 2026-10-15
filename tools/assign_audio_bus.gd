# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FindAudioStreamPlayersWithoutBus
extends EditorScript
## Finds AudioStreamPlayer and AudioStreamPlayer2D nodes which are configured to
## play to the Master bus.
##
## In general, audio nodes should be assigned to the Music or SFX bus, so that
## the volume controls work.
## [br][br]
## Run this tool in the editor from the command palette: Ctrl+Shift+P. Check the
## output in the Output tab.

const Util = preload("./util.gd")

## Ignore scenes in these folders
const EXCLUDE_FOLDERS: Array[String] = [
	"res://scenes/quests/story_quests/",
]


func _examine_node(scene_state: SceneState, idx: int) -> bool:
	var node_type := scene_state.get_node_type(idx)

	if node_type != &"AudioStreamPlayer" and node_type != &"AudioStreamPlayer2D":
		return false

	# A node that doesn't set the bus plays to the default one, Master.
	return Util.node_properties(scene_state, idx).get(&"bus", &"Master") == &"Master"


func _examine(scene: PackedScene) -> bool:
	var scene_state := scene.get_state()
	var needs_fix := false

	for idx: int in scene_state.get_node_count():
		if _examine_node(scene_state, idx):
			prints(
				scene.resource_path, scene_state.get_node_path(idx), "should be assigned to a bus"
			)
			needs_fix = true

	return needs_fix


func _should_check(scene_path: String) -> bool:
	for folder: String in EXCLUDE_FOLDERS:
		if scene_path.begins_with(folder):
			return false
	return true


func _run() -> void:
	var count: int = 0
	for scene: PackedScene in Util.find_scenes("res://", _should_check):
		if _examine(scene):
			count += 1
	prints(count, "scenes to fix")
