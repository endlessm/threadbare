# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")

@export var amount_of_items_to_collect: int = 3
@onready var items_container: HBoxContainer = $ItemsContainer_Objetos


func _ready() -> void:
	GameState.item_collected.connect(_on_item_collected)



func _on_item_collected(item: InventoryItem) -> void:
	if item.type not in [
		InventoryItem.ItemType.GLOVE,
		InventoryItem.ItemType.SHOES,
		InventoryItem.ItemType.BELT
	]:
		return  # Ignora personajes

	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if not item_slot.is_filled():
			item_slot.fill(item)
			return

func _items_collected_so_far() -> Array[InventoryItem]:
	var all_items := GameState.items_collected()
	var objetos := []

	for item in all_items:
		if item.type in [
			InventoryItem.ItemType.GLOVE,
			InventoryItem.ItemType.SHOES,
			InventoryItem.ItemType.BELT
		]:
			print("HUD objetos recibió: ", item)
			objetos.append(item)

	return objetos


func _on_item_consumed(item: InventoryItem) -> void:
	for child in items_container.get_children():
		var item_slot := child as ItemSlot
		if item_slot.is_filled_with_same_item_type_as(item):
			item_slot.free_slot()
			return
