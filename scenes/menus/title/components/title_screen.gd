# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var next_scene: PackedScene

@onready var button_box: VBoxContainer = %ButtonBox
@onready var start_button: Button = %StartButton


func _ready() -> void:
	while Pause.is_paused(Pause.System.PLAYER_INPUT):
		await Pause.pause_changed

	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	# Prevent repeated input
	button_box.queue_free()

	(
		SceneSwitcher
		. change_to_packed_with_transition(
			next_scene,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
