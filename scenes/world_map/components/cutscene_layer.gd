# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CutsceneLayer
extends CanvasLayer
## @experimental
##
## Play a cutscene animation in this overlay, and report back to [EternalLoom].
##
## Note: for this to work, the cutscenes root node must be [AnimationPlayer] and they must have
## an animation set to [member AnimationPlayer.autoplay].
##
## Warning: If the cutscenes have collision shapes, they may interfere with the physic objects
## below!

## Paths to scenes that will be shown as overlay. Their root node must be an AnimationPlayer.
@export var cutscene_paths: Array[String] = [
	"res://scenes/game_elements/fx/world_reweaven/components/world_reweaven_cutscene_1.tscn",
	"res://scenes/game_elements/fx/world_reweaven/components/world_reweaven_cutscene_2.tscn",
]

## The picked cutscene. Used to preload it.
var _cutscene_path: String
var _load_error: Error

## The Eternal Loom, for listening to signals and calling
## [member EternalLoom.on_cinematic_finished].
@onready var eternal_loom: EternalLoom = %EternalLoom


func _ready() -> void:
	eternal_loom.load_cinematic.connect(_on_eternal_loom_load_cinematic)
	eternal_loom.play_cinematic.connect(_on_eternal_loom_play_cinematic)


func _on_eternal_loom_load_cinematic() -> void:
	_cutscene_path = cutscene_paths.pick_random()
	_load_error = ResourceLoader.load_threaded_request(_cutscene_path)
	if _load_error != OK:
		push_error("Failed to start loading %s: %s" % [_cutscene_path, error_string(_load_error)])


func _on_eternal_loom_play_cinematic() -> void:
	if _load_error != OK:
		eternal_loom.on_cinematic_finished()
		return

	# Note: this is a hacky way of hidding the input HUD during the cutscene:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	player.remove_from_group(&"player")
	InputHud.refresh_scene_status()

	var cutscene_packed: PackedScene = ResourceLoader.load_threaded_get(_cutscene_path)
	var cutscene: AnimationPlayer = cutscene_packed.instantiate()

	var do_add: Callable = func() -> void: add_child(cutscene)
	Transitions.do_transition(do_add, Transition.Effect.FADE, Transition.Effect.FADE)

	await cutscene.animation_finished

	var do_remove: Callable = func() -> void: remove_child(cutscene)
	Transitions.do_transition(do_remove, Transition.Effect.FADE, Transition.Effect.FADE)

	player.add_to_group(&"player")

	eternal_loom.on_cinematic_finished()
