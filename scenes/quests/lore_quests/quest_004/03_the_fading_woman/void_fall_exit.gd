# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var dialogue: DialogueResource
@export_file("*.tscn") var next_scene: String = ""
@export var fall_time: float = 1.2

var _triggered: bool = false


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if _triggered:
		return
	if dialogue and resource != dialogue:
		return
	_triggered = true

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if is_instance_valid(player):
		player.set_physics_process(false)
		var t := create_tween().set_parallel(true)
		(
			t
			. tween_property(player, "scale", Vector2.ZERO, fall_time)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_IN)
		)
		t.tween_property(player, "modulate:a", 0.0, fall_time)
		await t.finished

	if not next_scene.is_empty():
		SceneSwitcher.change_to_file_with_transition(
			next_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)
