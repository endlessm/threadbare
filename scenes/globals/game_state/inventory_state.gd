# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InventoryState
extends Resource

## Emitted when a new item is collected and added to [member items].
signal item_collected(item: InventoryItem)

## Emitted when a item is consumed, causing it to be removed from
## [member items].
signal item_consumed(item: InventoryItem)

## Collected threads. Modify with [member add_collected_item] and
## [member clear_inventory].
@export var items: Array[InventoryItem]

## Types of items in [member inventory], for storage. Use [member inventory]
## in game code.
@export_storage var item_types: Array[String]:
	get():
		var types: Array[String]
		for item: InventoryItem in items:
			types.append(InventoryItem.ItemType.keys()[item.type])
		return types
	set(new_value):
		items = []
		for type_name: String in new_value:
			if InventoryItem.ItemType.has(type_name):
				items.append(InventoryItem.with_type(InventoryItem.ItemType[type_name]))
			else:
				push_warning("Ignoring unknown inventory item type: %s" % type_name)
		emit_changed()


## Add the [InventoryItem] to [member items].
func add_collected_item(item: InventoryItem) -> void:
	items.append(item)
	item_collected.emit(item)
	emit_changed()


## Remove all [InventoryItem]s from [member items].
func clear_inventory() -> void:
	for item: InventoryItem in items.duplicate():
		items.erase(item)
		item_consumed.emit(item)
	emit_changed()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"inventory":
			property.usage &= ~PROPERTY_USAGE_STORAGE
