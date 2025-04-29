# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var next_scene: PackedScene

@onready var main_menu: Control = %MainMenu
@onready var credits: Control = %Credits


func _on_start_pressed() -> void:
	(
		SceneSwitcher
		. change_to_packed_with_transition(
			next_scene,
			^"",
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_main_menu_credits_pressed() -> void:
	credits.show()


func _on_credits_back() -> void:
	main_menu.show()
