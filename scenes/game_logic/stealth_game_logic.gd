# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StealthGameLogic
extends Node

@export var items_needed: int = 3
var _items_collected: int = 0
var _completed: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	var scene := get_tree().current_scene.scene_file_path
	
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		guard.player_detected.connect(self._on_player_detected)
	
	for collectible in get_tree().get_nodes_in_group(&"collectible"):
		if MiniGameState.is_collected(collectible.name, scene):
			_items_collected += 1
			collectible.queue_free()
		else:
			collectible.item_collected.connect(self._on_item_collected)

func _on_item_collected(item: InventoryItem) -> void:
	if _completed:
		return
	_items_collected += 1
	if _items_collected >= items_needed:
		_completed = true
		MiniGameState.reset()
		GameState.add_collected_item(item)

func _on_player_detected(player: Node2D) -> void:
	if player.has_method("defeat"):
		player.defeat()
	else:
		push_warning("Detected node does not have defeat() method", player)
