# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")

@export var amount_of_items_to_collect: int = 3
@onready var items_container: HBoxContainer = %ItemsContainer_Personajes  # ✅ correcto


func _ready() -> void:
	# On ready, the HUD is populated with the items that were collected so
	# far in the quest.
	var items_collected := _items_collected_so_far()
	var slots := items_container.get_children()

	for i in range(min(items_collected.size(), slots.size())):
		var slot = slots[i]
		if slot is ItemSlot:
			slot.start_as_filled(items_collected[i])

	# Then, when each new item is collected, it is added to the progress UI
	GameState.item_collected.connect(self._on_item_collected)
	GameState.item_consumed.connect(self._on_item_consumed)



func _on_item_collected(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if not item_slot.is_filled():
			item_slot.fill(item)
			return


func _items_collected_so_far() -> Array[InventoryItem]:
	return GameState.items_collected_within_current_quest()


func _amount_of_items_collected() -> int:
	return GameState.amount_of_items_within_current_quest()


func _on_item_consumed(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if item_slot.is_filled_with_same_item_type_as(item):
			item_slot.free_slot()
			return
