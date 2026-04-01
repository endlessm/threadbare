# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

var zoom_tween: Tween


func _ready() -> void:
	GameState.abilities_changed.connect(_on_abilities_changed)
	_on_abilities_changed()


func _on_abilities_changed() -> void:
	var has_longer_thread := GameState.has_ability(Enums.PlayerAbilities.ABILITY_B_MODIFIER_1)
	var camera_zoom := Vector2(0.5, 0.5) if has_longer_thread else Vector2(1.0, 1.0)
	# Zoom out when the player can throw a longer thread:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera.zoom != camera_zoom:
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", camera_zoom, 1.0)
