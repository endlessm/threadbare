# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal all_threads_collected

@export_file("*.tscn") var next_scene: String = "uid://d4fbqrgy188p8"
@export var threads_required: int = 2

var _collected_count: int = 0
var _stealth_thread_types: Array[InventoryItem.ItemType] = []


func _ready() -> void:
	call_deferred(&"_sync_thread_progress")


func _sync_thread_progress() -> void:
	_stealth_thread_types.clear()

	for collectible: AnticuchoThreadCollectible in get_tree().get_nodes_in_group(
		&"anticucho_stealth_threads"
	):
		if collectible.item == null:
			continue

		if collectible.item.type not in _stealth_thread_types:
			_stealth_thread_types.append(collectible.item.type)

		if _inventory_has_type(collectible.item.type):
			collectible.queue_free()
			continue

		collectible.collected_in_stealth.connect(_on_thread_collected)

	_collected_count = _count_collected_stealth_threads()

	if _collected_count >= threads_required:
		_advance_to_next_scene()


func _inventory_has_type(item_type: InventoryItem.ItemType) -> bool:
	for item: InventoryItem in GameState.items_collected():
		if item.type == item_type:
			return true
	return false


func _count_collected_stealth_threads() -> int:
	var count := 0
	for item_type: InventoryItem.ItemType in _stealth_thread_types:
		if _inventory_has_type(item_type):
			count += 1
	return count


func _on_thread_collected() -> void:
	_collected_count = _count_collected_stealth_threads()
	if _collected_count < threads_required:
		return

	_advance_to_next_scene()


func _advance_to_next_scene() -> void:
	all_threads_collected.emit()

	if next_scene.is_empty():
		return

	GameState.set_challenge_start_scene(next_scene)
	SceneSwitcher.change_to_file_with_transition(
		next_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)
