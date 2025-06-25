# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

# Señales generales
signal item_collected(item: InventoryItem)
signal item_consumed(item: InventoryItem)
signal collected_items_changed(updated_items: Array[InventoryItem])

# Nuevas señales específicas ✨
signal character_items_changed(updated_items: Array[InventoryItem])
signal object_items_changed(updated_items: Array[InventoryItem])

# Inventarios
var inventory: Inventory = Inventory.new()
var story_quest_inventory: Inventory = Inventory.new()

var current_spawn_point: NodePath
var incorporating_threads: bool = false

# Inicia un nuevo quest
func start_quest() -> void:
	story_quest_inventory.clear()

# Añadir ítem al inventario general y del quest
func add_collected_item(item: InventoryItem) -> void:
	inventory.add_item(item)
	story_quest_inventory.add_item(item)
	item_collected.emit(item)
	collected_items_changed.emit(items_collected())  # Esta puede quedarse para cosas globales

	# NUEVO: Emitir según el tipo de ítem
	if item.source_game > 0:
		# Es un personaje
		var personajes := inventory.get_items().filter(func(i): return i.source_game > 0)
		character_items_changed.emit(personajes)
	else:
		# Es un objeto (guante, zapatos, cinturón)
		var objetos := inventory.get_items().filter(func(i): return i.source_game == 0)
		object_items_changed.emit(objetos)

# Eliminar ítem del inventario
func remove_consumed_item(item: InventoryItem) -> void:
	inventory.remove_item(item)
	story_quest_inventory.remove_item(item)
	item_consumed.emit(item)
	collected_items_changed.emit(items_collected())

	# Vuelve a emitir la lista actualizada para cada HUD
	if item.source_game > 0:
		var personajes := inventory.get_items().filter(func(i): return i.source_game > 0)
		character_items_changed.emit(personajes)
	else:
		var objetos := inventory.get_items().filter(func(i): return i.source_game == 0)
		object_items_changed.emit(objetos)


# Obtener todos los ítems
func items_collected() -> Array[InventoryItem]:
	return inventory.get_items()

# Obtener ítems del quest activo
func items_collected_within_current_quest() -> Array[InventoryItem]:
	return story_quest_inventory.get_items()

# Cantidad de ítems del quest
func amount_of_items_within_current_quest() -> int:
	return story_quest_inventory.amount_of_items()
