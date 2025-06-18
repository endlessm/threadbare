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
	ItemType.MEMORY: preload("uid://brspc1u02oawt"),
	ItemType.IMAGINATION: preload("uid://wyiamtqmp4gk"),
	ItemType.SPIRIT: preload("uid://c4fefrg0tfkpl")
}

const WORLD_TEXTURES: Dictionary[ItemType, Texture2D] = {
	ItemType.MEMORY: preload("uid://5wscjc8yqqts"),
	ItemType.IMAGINATION: preload("uid://6bf8rum68wq3"),
	ItemType.SPIRIT: preload("uid://cepg1o3ihp055")
}

@export var name: String
@export var type: ItemType
@export var source_game: int = 0 


func same_type_as(other_item: InventoryItem) -> bool:
	return type == other_item.type


func get_world_texture() -> Texture2D:
	match source_game:
		1:
			return preload("res://.godot/imported/Adan_personaje1.png-fd806689568ade8573381b32fcfefbc5.ctex")
		2:
			return preload("res://.godot/imported/Killian_personaje2.png-c205b6eceb037da5173f4d54b9b7ea84.ctex")
		3:
			return preload("res://.godot/imported/Mia_personaje3.png-9ff9e7ffe00c2f22a66a9fa6c03484ae.ctex")
		_:
			return WORLD_TEXTURES.get(type, null)

static func texture_for_type(a_type: ItemType) -> Texture2D:
	return TEXTURES[a_type]
	
func texture() -> Texture2D:
	return get_world_texture()

static func with_type(a_type: ItemType) -> InventoryItem:
	var item := new()
	item.type = a_type
	return item


static func item_types() -> Array:
	return ItemType.values()


func type_name() -> String:
	return ItemType.find_key(type).to_pascal_case()
