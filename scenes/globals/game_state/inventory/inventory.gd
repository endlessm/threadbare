# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Inventory
extends Resource

@export var _items: Array[InventoryItem]


func get_items() -> Array[InventoryItem]:
	return _items.duplicate()


func clear() -> void:
	_items.clear()


func has_item(item: InventoryItem) -> bool:
	return item in _items


func add_item(item: InventoryItem) -> void:
	if not item in _items:
		_items.push_back(item)


func remove_item(item: InventoryItem) -> void:
	_items.erase(item)


func amount_of_items() -> int:
	return _items.size()
