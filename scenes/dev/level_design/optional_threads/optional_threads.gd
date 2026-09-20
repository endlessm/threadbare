# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var dark_sky_color: Color
var _tween: Tween

@onready var cave_lighting: Area2D = %CaveLighting
@onready var canvas_modulate: CanvasModulate = %CanvasModulate
@onready var optional_collectible_item: CollectibleItem = %OptionalCollectibleItem


func _ready() -> void:
	optional_collectible_item.tree_exiting.connect(func() -> void: optional_collectible_item = null)
	cave_lighting.body_entered.connect(_on_cave_lighting_body_entered)
	cave_lighting.body_exited.connect(_on_cave_lighting_body_exited)


func _adjust_modulation(target: Color) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(canvas_modulate, "color", target, 0.5)


func _on_cave_lighting_body_entered(_body: Node2D) -> void:
	_adjust_modulation(dark_sky_color)


func _on_cave_lighting_body_exited(_body: Node2D) -> void:
	_adjust_modulation(Color.WHITE)
