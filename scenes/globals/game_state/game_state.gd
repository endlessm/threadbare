# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

signal item_collected(item: InventoryItem)
signal item_consumed(item: InventoryItem)
signal collected_items_changed(updated_items: Array[InventoryItem])

const GAME_STATE_PATH := "user://game_state.cfg"
const INVENTORY_SECTION := "inventory"
const INVENTORY_ITEMS_AMOUNT_KEY := "amount_of_items_collected"
const QUEST_SECTION := "quest"
const QUEST_PATH_KEY := "resource_path"
const QUEST_CURRENTSCENE_KEY := "current_scene"
const QUEST_SPAWNPOINT_KEY := "current_spawn_point"
const GLOBAL_SECTION := "global"
const GLOBAL_INCORPORATING_THREADS_KEY := "incorporating_threads"
const COLLECTIBLES_SECTION := "collectibles"
const COLLECTED_IDS_KEY := "collected_ids"

const TRANSIENT_SCENES := [
	"res://scenes/menus/title/title_screen.tscn",
	"res://scenes/menus/intro/intro.tscn",
]

@export var inventory: Array[InventoryItem] = []
@export var current_spawn_point: NodePath

var incorporating_threads: bool = false
var persist_progress: bool
var _state := ConfigFile.new()
var collected_ids: Array[String] = []

func _ready() -> void:
	var initial_scene_uid := ResourceLoader.get_resource_uid(
		get_tree().current_scene.scene_file_path
	)
	var main_scene_uid := ResourceLoader.get_resource_uid(
		ProjectSettings.get_setting("application/run/main_scene")
	)
	persist_progress = initial_scene_uid == main_scene_uid
	if not persist_progress:
		return
	var err := _state.load(GAME_STATE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [GAME_STATE_PATH, err])

func set_incorporating_threads(new_incorporating_threads: bool) -> void:
	incorporating_threads = new_incorporating_threads
	_state.set_value(GLOBAL_SECTION, GLOBAL_INCORPORATING_THREADS_KEY, incorporating_threads)
	_save()

func start_quest(quest: Quest) -> void:
	_do_clear_inventory()
	_update_inventory_state()
	_state.set_value(QUEST_SECTION, QUEST_PATH_KEY, quest.resource_path)
	_do_set_scene(quest.first_scene, ^"")
	_save()

func set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if scene_path in TRANSIENT_SCENES:
		return
	_do_set_scene(scene_path, spawn_point)
	_save()

func set_current_spawn_point(spawn_point: NodePath = ^"") -> void:
	current_spawn_point = spawn_point
	_state.set_value(QUEST_SECTION, QUEST_SPAWNPOINT_KEY, current_spawn_point)
	_save()

func _do_set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	current_spawn_point = spawn_point
	_state.set_value(QUEST_SECTION, QUEST_CURRENTSCENE_KEY, scene_path)
	_state.set_value(QUEST_SECTION, QUEST_SPAWNPOINT_KEY, current_spawn_point)

func add_collected_item(item: InventoryItem) -> void:
	inventory.append(item)
	item_collected.emit(item)
	collected_items_changed.emit(items_collected())
	_update_inventory_state()
	_save()

func clear_inventory() -> void:
	_do_clear_inventory()
	_update_inventory_state()
	_save()

func _do_clear_inventory() -> void:
	for item: InventoryItem in inventory.duplicate():
		inventory.erase(item)
		item_consumed.emit(item)
	collected_items_changed.emit(items_collected())

func items_collected() -> Array[InventoryItem]:
	return inventory.duplicate()

func _update_inventory_state() -> void:
	var amount: int = clamp(inventory.size(), 0, InventoryItem.ItemType.size())
	_state.set_value(INVENTORY_SECTION, INVENTORY_ITEMS_AMOUNT_KEY, amount)

func clear() -> void:
	_state.clear()
	_save()

func can_restore() -> bool:
	return _state.get_sections().size()

func get_scene_to_restore() -> String:
	return _state.get_value(QUEST_SECTION, QUEST_CURRENTSCENE_KEY, "")

func restore() -> Dictionary:
	var loaded_ids = _state.get_value(COLLECTIBLES_SECTION, COLLECTED_IDS_KEY, [])
	collected_ids.clear()
	if loaded_ids is Array:
		for id in loaded_ids:
			if typeof(id) == TYPE_STRING:
				collected_ids.append(id)
	var amount_in_state: int = _state.get_value(INVENTORY_SECTION, INVENTORY_ITEMS_AMOUNT_KEY, 0)
	var amount: int = clamp(amount_in_state, 0, InventoryItem.ItemType.size())
	inventory.clear()
	for index in range(amount):
		var item := InventoryItem.with_type(index)
		inventory.append(item)
	var scene_path: String = _state.get_value(QUEST_SECTION, QUEST_CURRENTSCENE_KEY, "")
	current_spawn_point = _state.get_value(QUEST_SECTION, QUEST_SPAWNPOINT_KEY, ^"")
	incorporating_threads = _state.get_value(
		GLOBAL_SECTION, GLOBAL_INCORPORATING_THREADS_KEY, false
	)
	return {"scene_path": scene_path, "spawn_point": current_spawn_point}

func has_collected(unique_id: String) -> bool:
	return collected_ids.has(unique_id)

func mark_collected(unique_id: String, item: InventoryItem) -> void:
	if not has_collected(unique_id):
		collected_ids.append(unique_id)
		add_collected_item(item)  # maneja inventario + señales

func _save() -> void:
	if not persist_progress:
		return
	_state.set_value(COLLECTIBLES_SECTION, COLLECTED_IDS_KEY, collected_ids)
	var err := _state.save(GAME_STATE_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [GAME_STATE_PATH, err])
