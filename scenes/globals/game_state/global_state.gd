# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name GlobalState
extends Resource

## Emitted when a new item is collected.
signal item_collected(item: InventoryItem)

## Emitted when a item is consumed, causing it to be removed from the
## [member inventory].
signal item_consumed(item: InventoryItem)

## Emitted when a quest is added or removed from [member completed_quests].
signal completed_quests_changed

## Emitted when the [member helper] changes.
signal helper_changed

## Inventory of collected threads. Modify with [member add_collected_item] and
## [member clear_inventory].
@export var inventory: Array[InventoryItem]

## Types of items in [member inventory], for storage. Use [member inventory]
## in game code.
@export_storage var inventory_item_types: Array[String]:
	get():
		var types: Array[String]
		for item: InventoryItem in inventory:
			types.append(InventoryItem.ItemType.keys()[item.type])
		return types
	set(new_value):
		var items: Array[InventoryItem]
		for type_name: String in new_value:
			if InventoryItem.ItemType.has(type_name):
				items.append(InventoryItem.with_type(InventoryItem.ItemType[type_name]))
			else:
				push_warning("Ignoring unknown inventory item type: %s" % type_name)
		inventory = items
		emit_changed()

## [Quest]s which the player has previously completed. Modify this with
## [method set_quest_completed_state].
@export var completed_quests: Array[Quest]

## Paths to completed quests. This is what is actually stored in the game state,
## rather than referring to the [Quest] resources directly, so that deleting a
## quest resource from the game doesn't break loading the save file. Use [member
## completed_quests] and [method set_quest_completed_state] in game code.
@export var completed_quest_paths: Array[String]:
	get():
		var paths: Array[String]
		for quest: Quest in completed_quests:
			paths.append(quest.resource_path)
		return paths
	set(new_value):
		var quests: Array[Quest]
		for path: String in new_value:
			if ResourceLoader.exists(path):
				var quest: Quest = ResourceLoader.load(path)
				quests.append(quest)
			else:
				push_warning("Ignoring unknown quest in save file: %s" % path)
		completed_quests = quests
		completed_quests_changed.emit()
		emit_changed()

## Global player state. During a quest, [member QuestState.player] should be
## used instead. [GameState.player] always points to the correct instance.
@export var player: PlayerState = PlayerState.new()

@export var helper: HelperCharacterState


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"completed_quests", "inventory":
			property.usage &= ~PROPERTY_USAGE_STORAGE


## Add the [InventoryItem] to the [member inventory].
func add_collected_item(item: InventoryItem) -> void:
	inventory.append(item)
	item_collected.emit(item)
	emit_changed()


## Remove all [InventoryItem]s from the [member inventory].
func clear_inventory() -> void:
	for item: InventoryItem in inventory.duplicate():
		inventory.erase(item)
		item_consumed.emit(item)
	emit_changed()


## Updates [member completed_quests] to include [param quest] if [param
## is_completed] is true, or remove [param quest] if [param is_completed] is
## false.
func set_quest_completed_state(quest: Quest, is_completed: bool) -> void:
	if is_completed:
		if quest not in completed_quests:
			completed_quests.append(quest)
			completed_quests_changed.emit()
			emit_changed()
	else:
		while quest in completed_quests:
			completed_quests.erase(quest)
			completed_quests_changed.emit()
			emit_changed()


## Obtain the help from a townie, for using it later in the game.
func obtain_help(new_helper_type: InventoryItem.ItemType, new_character_seed: int) -> void:
	helper = HelperCharacterState.new()
	helper.helper_type = new_helper_type
	helper.character_seed = new_character_seed
	helper_changed.emit()
	emit_changed()


## Consume the help after using it.
func clear_help() -> void:
	helper = null
	helper_changed.emit()
	emit_changed()
