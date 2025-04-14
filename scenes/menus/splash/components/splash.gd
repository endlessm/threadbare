# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const NEXT_SCENE: PackedScene = preload("res://scenes/menus/intro/intro.tscn")

@onready var logo_stitcher: LogoStitcher = %LogoStitcher
@onready var scene_switch_timer: Timer = %SceneSwitchTimer


func _ready() -> void:
	logo_stitcher.finished.connect(scene_switch_timer.start)
	scene_switch_timer.timeout.connect(switch_to_intro)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		switch_to_intro()


func switch_to_intro() -> void:
	scene_switch_timer.timeout.disconnect(switch_to_intro)
	SceneSwitcher.change_to_packed_with_transition(
		NEXT_SCENE, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
