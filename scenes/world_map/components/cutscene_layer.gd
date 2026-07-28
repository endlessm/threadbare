# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CutsceneLayer
extends CanvasLayer

## Paths to scenes that will be shown as overlay.
@export var cutscene_paths: Array[String] = [
	"res://scenes/game_elements/fx/world_reweaven/components/world_reweaven_cutscene_1.tscn",
	"res://scenes/game_elements/fx/world_reweaven/components/world_reweaven_cutscene_2.tscn",
]

var cutscene_path: String
var load_error: Error

## The Eternal Loom, for listening to signals and calling
## [member EternalLoom.on_cinematic_finished()].
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready() -> void:
	eternal_loom.load_cinematic.connect(_on_eternal_loom_load_cinematic)
	eternal_loom.play_cinematic.connect(_on_eternal_loom_play_cinematic)


func _on_eternal_loom_load_cinematic() -> void:
	cutscene_path = cutscene_paths.pick_random()
	load_error = ResourceLoader.load_threaded_request(cutscene_path)
	if load_error != OK:
		push_error("Failed to start loading %s: %s" % [cutscene_path, error_string(load_error)])


func _on_eternal_loom_play_cinematic() -> void:
	if load_error != OK:
		eternal_loom.on_cinematic_finished()
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	player.remove_from_group("player")
	InputHud.refresh_scene_status()

	var cutscene_packed: PackedScene = ResourceLoader.load_threaded_get(cutscene_path)
	var cutscene: Cutscene = cutscene_packed.instantiate()
	var do_add: Callable = func() -> void:
		cutscene.position = get_viewport().get_visible_rect().size / 2
		add_child(cutscene)
	Transitions.do_transition(do_add, Transition.Effect.FADE, Transition.Effect.FADE)

	await cutscene.finished
	var do_remove: Callable = func() -> void: remove_child(cutscene)
	Transitions.do_transition(do_remove, Transition.Effect.FADE, Transition.Effect.FADE)

	player.add_to_group("player")

	eternal_loom.on_cinematic_finished()
