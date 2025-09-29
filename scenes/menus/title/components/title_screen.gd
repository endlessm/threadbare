# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var next_scene: PackedScene

@onready var main_menu: Control = %MainMenu
@onready var options: Control = %Options
@onready var credits: Control = %Credits


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()


func _on_main_menu_continue_pressed() -> void:
	var saved_scene: Dictionary = GameState.restore()
	(
		SceneSwitcher
		. change_to_file_with_transition(
			saved_scene["scene_path"],
			saved_scene["spawn_point"],
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_start_pressed() -> void:
	if GameState.can_restore():
		GameState.clear()
	(
		SceneSwitcher
		. change_to_packed_with_transition(
			next_scene,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_main_menu_options_pressed() -> void:
	options.show()


func _on_main_menu_credits_pressed() -> void:
	credits.show()


func _on_credits_back() -> void:
	main_menu.show()


func _on_options_back() -> void:
	main_menu.show()
