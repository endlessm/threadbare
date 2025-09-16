# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control


const NEXT_SCENE: PackedScene = preload("uid://stdqc6ttomff")

@onready var click_button: Button = $ClickLayer/ClickToStartButton
@onready var logo_stitcher: LogoStitcher = %LogoStitcher
@onready var scene_switch_timer: Timer = %SceneSwitchTimer



func _ready() -> void:
	
	click_button.visible = true
	get_tree().paused = true
	click_button.pressed.connect(click_to_start)
	logo_stitcher.finished.connect(scene_switch_timer.start)
	scene_switch_timer.timeout.connect(switch_to_intro)
	

func click_to_start() -> void:
	click_button.visible = false
	get_tree().paused = false

	logo_stitcher.finished.connect(scene_switch_timer.start)
	scene_switch_timer.timeout.connect(
		func(): get_tree().change_scene_to_packed(NEXT_SCENE)
	)


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
	SceneSwitcher.change_to_packed_with_transition(
		NEXT_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
