# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var touchscreen_warning: PanelContainer = $TouchscreenWarning



@export var tutorial_quest: Quest

@onready var main_menu: Control = %MainMenu
@onready var options: Control = %Options
@onready var credits: Control = %Credits


func _ready() -> void:
	if ProjectSettings.get_setting(ThreadbareProjectSettings.SKIP_SPLASH):
		if GameState.can_restore():
			_on_main_menu_continue_pressed()
		else:
			_on_start_pressed()
			
	$TouchscreenWarning/VBoxContainer/DismissButton.pressed.connect(_on_dismiss_pressed)
	if _should_show_touchscreen_warning():
		touchscreen_warning.show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()


func _on_main_menu_continue_pressed() -> void:
	(
		SceneSwitcher
		. change_to_file_with_transition(
			GameState.scene.path,
			GameState.scene.spawn_point,
			Transition.Effect.FADE,
			Transition.Effect.FADE,
		)
	)


func _on_start_pressed() -> void:
	GameState.clear()

	GameState.start_quest(tutorial_quest)
	SceneSwitcher.change_to_file_with_transition(
		tutorial_quest.first_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _on_main_menu_options_pressed() -> void:
	options.show()


func _on_main_menu_credits_pressed() -> void:
	credits.show()


func _on_credits_back() -> void:
	main_menu.show()


func _on_options_back() -> void:
	main_menu.show()

func _should_show_touchscreen_warning() -> bool:
	if OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linuxbsd"):
		return false

	var has_touch: bool = DisplayServer.is_touchscreen_available()
	
	var has_keyboard: bool = false
	
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		has_keyboard = false
	else:
		has_keyboard = DisplayServer.has_hardware_keyboard()

	if has_touch and not has_keyboard:
		return true
		
	return false

func _on_dismiss_pressed() -> void:
	touchscreen_warning.hide()
