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


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(&"dialogue_next")
		or event.is_action_pressed(&"dialogue_skip")
		or event.is_action_pressed(&"pause")
	):
		get_viewport().set_input_as_handled()
		switch_to_intro()


func switch_to_intro() -> void:
	scene_switch_timer.timeout.disconnect(switch_to_intro)
	scene_link.switch()
