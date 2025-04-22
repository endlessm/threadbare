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

const TEXTURES: Dictionary[ItemType, Texture2D] = {
	ItemType.MEMORY: preload("res://assets/collectibles/memory.png"),
	ItemType.IMAGINATION: preload("res://assets/collectibles/imagination.png"),
	ItemType.SPIRIT: preload("res://assets/collectibles/spirit.png")
}

const WORLD_TEXTURES: Dictionary[ItemType, Texture2D] = {
	ItemType.MEMORY: preload("res://assets/collectibles/world_memory.png"),
	ItemType.IMAGINATION: preload("res://assets/collectibles/world_imagination.png"),
	ItemType.SPIRIT: preload("res://assets/collectibles/world_spirit.png")
}

@export var name: String
@export var type: ItemType


func same_type_as(other_item: InventoryItem) -> bool:
	return type == other_item.type


func texture() -> Texture2D:
	return texture_for_type(type)


func get_world_texture() -> Texture2D:
	return WORLD_TEXTURES[type]


static func texture_for_type(a_type: ItemType) -> Texture2D:
	return TEXTURES[a_type]


static func with_type(a_type: ItemType) -> InventoryItem:
	var item := new()
	item.type = a_type
	return item


static func item_types() -> Array:
	return ItemType.values()
