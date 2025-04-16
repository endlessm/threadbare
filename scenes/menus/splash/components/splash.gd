# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const NEXT_SCENE: PackedScene = preload("res://scenes/menus/intro/intro.tscn")

@onready var logo_stitcher: LogoStitcher = %LogoStitcher
@onready var scene_switch_timer: Timer = %SceneSwitchTimer


func _ready() -> void:
	logo_stitcher.finished.connect(scene_switch_timer.start)
	scene_switch_timer.timeout.connect(switch_to_intro)


func _input(event: InputEvent) -> void:
	if (
		not Pause.is_paused(Pause.System.PLAYER_INPUT)
		and (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"))
	):
		get_viewport().set_input_as_handled()
		switch_to_intro()


func switch_to_intro() -> void:
	scene_switch_timer.timeout.disconnect(switch_to_intro)
	SceneSwitcher.change_to_packed_with_transition(
		NEXT_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
