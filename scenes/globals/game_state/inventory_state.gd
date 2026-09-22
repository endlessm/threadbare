# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name InventoryState
extends Resource

## Emitted when a new item is collected and added to [member items].
signal item_collected(item: TaggedItem)

## Emitted when a item is consumed, causing it to be removed from
## [member items].
signal item_consumed(item: TaggedItem)

## Collected threads. Modify with [member add_collected_item] and
## [member clear_inventory].
@export var items: Array[TaggedItem]


## Move all items from [param other] to this inventory.
func merge(other: InventoryState) -> void:
	for ci: TaggedItem in other.items:
		if not _has(ci):
			_add(ci)
	other.clear_inventory()


## Returns true if the inventory contains [param item],
## collected in the current quest (TODO), specifically from [param source_node]
## (if provided).
func has(item: InventoryItem, source_node: Node = null) -> bool:
	# TODO: should the caller make the TaggedItem instead?
	return _has(TaggedItem.make(item, GameState.quest.quest, source_node))


## Add [param item] to [member items], tagging it as having been collected in
## the current quest from [param source_node].
func add_collected_item(item: InventoryItem, source_node: Node = null) -> void:
	_add(TaggedItem.make(item, GameState.quest.quest, source_node))


func _has(ci: TaggedItem) -> bool:
	return items.find_custom(ci.matches) >= 0


func _add(ci: TaggedItem) -> void:
	if _has(ci):
		return

	items.append(ci)
	item_collected.emit(ci)
	emit_changed()


## Remove all items from [member items].
func clear_inventory() -> void:
	for ci: TaggedItem in items.duplicate():
		items.erase(ci)
		item_consumed.emit(ci)
	emit_changed()
