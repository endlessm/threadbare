# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

@export var camera: Camera2D
@export var void_layer: TileMapCover
@export var enemy: CharacterBody2D

@onready var interact_area: InteractArea = $InteractArea
@onready var timer: Timer = $Timer


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	enemy.queue_free()

	var tween := create_tween()
	var original_zoom := camera.zoom
	tween.tween_property(camera, "zoom", original_zoom / 4.0, 1.0).set_ease(Tween.EASE_OUT)
	#tween.parallel().tween_property(void_layer, "modulate:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
	#tween.tween_property(camera, "zoom", original_zoom, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	#timer.stop()
	#void_layer.enabled = false
	interact_area.end_interaction()
	interact_area.disabled = true
