# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@onready var logo_stitcher: LogoStitcher = %LogoStitcher
@onready var scene_switch_timer: Timer = %SceneSwitchTimer
@onready var scene_link: SceneLink = %SceneLink


func _ready() -> void:
	if ProjectSettings.get_setting(ThreadbareProjectSettings.SKIP_SPLASH):
		SceneSwitcher.change_to_file.call_deferred(scene_link.next_scene)
		return
	logo_stitcher.finished.connect(scene_switch_timer.start)
	scene_switch_timer.timeout.connect(switch_to_intro)


func _input(event: InputEvent) -> void:
	# On touchscreens, a tap anywhere skips the splash. This is in _input()
	# rather than _unhandled_input() because the controls of the splash would
	# otherwise take the touch first.
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		switch_to_intro()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(&"dialogue_next")
		or event.is_action_pressed(&"dialogue_skip")
		or event.is_action_pressed(&"pause")
	):
		get_viewport().set_input_as_handled()
		switch_to_intro()


func switch_to_intro() -> void:
	# A second tap or key press during the transition would switch again.
	if not scene_switch_timer.timeout.is_connected(switch_to_intro):
		return
	scene_switch_timer.timeout.disconnect(switch_to_intro)
	scene_link.switch()
