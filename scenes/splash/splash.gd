# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
extends Node2D


func _ready() -> void:
	$LogoStitcher.finished.connect(_on_logo_stitcher_finished)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"ui_accept"):
		switch_to_intro()


func switch_to_intro() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/intro/intro.tscn"))


func _on_logo_stitcher_finished() -> void:
	await get_tree().create_timer(5.0).timeout
	switch_to_intro()
