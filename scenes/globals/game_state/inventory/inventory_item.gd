# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InventoryItem
extends Resource

enum ItemType {
	MEMORY,
	IMAGINATION,
	SPIRIT,
}

@export var type: ItemType
@export var color: Color
@export var hud_texture: Texture2D
@export var world_texture: Texture2D


# TODO: can we eliminate this?
static func with_type(a_type: ItemType) -> InventoryItem:
	match a_type:
		ItemType.MEMORY:
			return load("res://scenes/globals/game_state/inventory/memory.tres")
		ItemType.IMAGINATION:
			return load("res://scenes/globals/game_state/inventory/imagination.tres")
		ItemType.SPIRIT:
			return load("res://scenes/globals/game_state/inventory/spirit.tres")
		_:
			push_error("Unknown ItemType %d" % a_type)
			return null


func type_name() -> String:
	return ItemType.find_key(type).to_pascal_case()
