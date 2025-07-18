# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@export var void_layer: TileMapLayer
@onready var interact_area: InteractArea = $InteractArea
@onready var camera_2d: Camera2D = $"../Player/Camera2D"
@onready var floor_destroying_enemy: CharacterBody2D = $"../FloorDestroyingEnemy"


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	floor_destroying_enemy.queue_free()

	var tween := create_tween()
	var original_zoom := camera_2d.zoom
	tween.tween_property(camera_2d, "zoom", original_zoom / 4.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(void_layer, "modulate:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_2d, "zoom", original_zoom, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	void_layer.enabled = false
	interact_area.end_interaction()
	interact_area.disabled = true
