# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

const NEXT_SCENE: PackedScene = preload("res://scenes/menus/intro/intro.tscn")


func _ready() -> void:
	$LogoStitcher.finished.connect(_on_logo_stitcher_finished)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		switch_to_intro()


func switch_to_intro() -> void:
	SceneSwitcher.change_to_packed(NEXT_SCENE)


func _on_logo_stitcher_finished() -> void:
	await get_tree().create_timer(5.0).timeout
	switch_to_intro()
