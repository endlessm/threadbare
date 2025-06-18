# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")

@onready var items_container: HBoxContainer = %ItemsContainer


func _ready() -> void:
	# On ready, the HUD is populated with the items that were collected so
	# far in the quest.
	var items_collected := GameState.items_collected()
	for i: int in clamp(items_collected.size(), 0, InventoryItem.ItemType.size()):
		items_container.get_child(i).start_as_filled(items_collected[i])
	# Then, when each new item is collected, it is added to the progress UI
	GameState.item_collected.connect(self._on_item_collected)
	GameState.item_consumed.connect(self._on_item_consumed)


func _on_item_collected(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if not item_slot.is_filled():
			item_slot.fill(item)
			return


func _on_item_consumed(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if item_slot.is_filled_with_same_item_type_as(item):
			item_slot.free_slot()
