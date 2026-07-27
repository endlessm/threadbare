# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var dark_sky_color: Color

var _tween: Tween

@onready var canvas_modulate: CanvasModulate = %CanvasModulate

# Used by dialogue
@onready var memory_thread: CollectibleItem = %MemoryThread
@onready var hud: CanvasLayer = %HUD


func _adjust_modulation(target: Color) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(canvas_modulate, "color", target, 0.5)


func _on_cave_lighting_body_entered(_body: Node2D) -> void:
	_adjust_modulation(dark_sky_color)


func _on_cave_lighting_body_exited(_body: Node2D) -> void:
	_adjust_modulation(Color.WHITE)
