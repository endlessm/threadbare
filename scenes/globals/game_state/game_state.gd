# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

## Emited when a new item is collected, even if it wasn't added to the
## inventory due to it being already there.
signal item_collected(item: InventoryItem)

## Global inventory, used to track the items the player obtains and that
## can be added to the loom.
@export var inventory: Inventory = Inventory.new()
@export var current_spawn_point: NodePath

## Quest's items. Used to track the progress withing a story quest.
var story_quest_inventory: Inventory = Inventory.new()


## Resets the [member story_quest_inventory]. This needs to be called when
## a new story quest starts.
func start_quest() -> void:
	story_quest_inventory.clear()


## Adds the [InventoryItem] to the [member inventory] and the
## [member story_quest_inventory], provided it wasn't already there.
func add_collected_item(item: InventoryItem) -> void:
	inventory.add_item(item)
	story_quest_inventory.add_item(item)
	item_collected.emit(item)


## Returns the items in the [member story_quest_inventory].[br]
## Instead of returning a reference to the inventory or its internals, it
## returns a new array.
func items_collected_within_current_quest() -> Array[InventoryItem]:
	return story_quest_inventory.get_items()


## Returns the amount of items in the [member story_quest_inventory].
func amount_of_items_within_current_quest() -> int:
	return story_quest_inventory.amount_of_items()
