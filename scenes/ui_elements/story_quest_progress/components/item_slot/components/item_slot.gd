# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ItemSlot extends TextureRect

## UI slot for [InventoryItem]s.

var filled_with_item: InventoryItem = null:
	set(new_item):
		filled_with_item = new_item
		if filled_with_item:
			texture = filled_with_item.hud_texture

var _ghost := false:
	set(new_value):
		_ghost = new_value
		(material as ShaderMaterial).set_shader_parameter("intensity", 0.25 if _ghost else 0.0)

@onready var animation_player: AnimationPlayer = $AnimationPlayer


## Shows the collected [InventoryItem] in this item slot without animation.
func start_as_filled(inventory_item: InventoryItem, ghost: bool) -> void:
	if is_filled():
		return

	_ghost = ghost
	filled_with_item = inventory_item
	modulate = Color.WHITE


func is_filled() -> bool:
	return filled_with_item != null


## Shows the collected [InventoryItem] in this item slot with a quick animation.
func fill(inventory_item: InventoryItem, ghost: bool) -> void:
	if is_filled():
		return

	_ghost = ghost
	filled_with_item = inventory_item
	texture = inventory_item.hud_texture
	pivot_offset = size / 2.0
	animation_player.play(&"item_collected")
	await animation_player.animation_finished


func is_filled_with_same_item_type_as(inventory_item: InventoryItem) -> bool:
	return is_filled() and filled_with_item.type == inventory_item.type


func free_slot() -> void:
	filled_with_item = null
	modulate = Color(Color.BLACK, 0.7)
	_ghost = false
