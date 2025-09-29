# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends NPC
## @experimental

@export var camera: Camera2D
@export var void_layer: TileMapCover
@export var enemy: CharacterBody2D

var _repelled := false

@onready var interact_area: InteractArea = $InteractArea


func repel_void() -> void:
	enemy.queue_free()

	var tween := create_tween()
	var original_zoom := camera.zoom
	tween.tween_property(camera, "zoom", original_zoom / 4.0, 1.0).set_ease(Tween.EASE_OUT)
	await tween.finished

	GameState.add_collected_item(InventoryItem.with_type(InventoryItem.ItemType.MEMORY))

	await void_layer.uncover_all(3.0)

	tween = create_tween()
	tween.tween_property(camera, "zoom", original_zoom, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished

	GameState.add_collected_item(InventoryItem.with_type(InventoryItem.ItemType.IMAGINATION))

	_repelled = true
