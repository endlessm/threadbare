# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

const ITEM_SLOT: PackedScene = preload("uid://1mjm4atk2j6e")
@onready var items_container: HBoxContainer = %ItemsContainer

var fragmentos_recibidos: int = 0

func _ready() -> void:
	if not GameState.current_quest or GameState.current_quest.threads_to_collect == 0:
		visible = false
		return

	# Forzamos 3 espacios visuales siempre
	var slots_visuales = 3
	for _i in slots_visuales:
		items_container.add_child(ITEM_SLOT.instantiate())

	var items_collected := GameState.items_collected()
	fragmentos_recibidos = items_collected.size()
	var hilos_completos = fragmentos_recibidos / 3

	for i: int in min(hilos_completos, slots_visuales):
		if items_collected.size() > 0:
			items_container.get_child(i).start_as_filled(items_collected[0])

	GameState.item_collected.connect(self._on_item_collected)
	GameState.item_consumed.connect(self._on_item_consumed)

func _on_item_collected(item: InventoryItem) -> void:
	fragmentos_recibidos += 1
	
	if fragmentos_recibidos % 3 == 0:
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
