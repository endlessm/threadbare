# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends TextureRect

## UI slot for [InventoryItem]s.

var filled_with_item: InventoryItem = null:
	set(new_item):
		filled_with_item = new_item
		texture = filled_with_item.texture()

@onready var animation_player: AnimationPlayer = $AnimationPlayer


## Shows the collected [InventoryItem] in this item slot without animation.
func start_as_filled(inventory_item: InventoryItem) -> void:
	if is_filled():
		return

	filled_with_item = inventory_item
	modulate = Color.WHITE


func is_filled() -> bool:
	return filled_with_item != null


## Shows the collected [InventoryItem] in this item slot with a quick animation.
func fill(inventory_item: InventoryItem) -> void:
	if is_filled():
		return

	filled_with_item = inventory_item
	texture = inventory_item.texture()
	pivot_offset = size / 2.0
	animation_player.play(&"item_collected")
	await animation_player.animation_finished
