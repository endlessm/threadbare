# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Checkpoint
class_name CheckpointVoid

# This checkpoint variation will allow some enemies to bypass the scene 
# reset after re-spawning in a checkpoint, keeping their tilemap changes
# and last positions

# Static variables
static var saved_enemy_states: Dictionary = {}
static var saved_consumed_tiles: Array[Vector2i] = []
static var pending_consumed_tiles: Array[Vector2i] = []
static var _tracker_instance: Node = null

# Variables you need to assign in Inspector
## Assign the enemies you want to bypass the reset scene
@export var persistent_enemies: Array[CharacterBody2D]

## Assign the modified layer
@export var shared_void_layer: Node2D

const _NEIGHBORS := [
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

func _ready() -> void:
	super._ready()
	
	if Engine.is_editor_hint():
		return
	
	if _tracker_instance == null or not is_instance_valid(_tracker_instance):
		_tracker_instance = self
		# Clears pending tiles consumed in case the player doesn't reach the checkpoint
		pending_consumed_tiles.clear()
		
	# Restores the enemy state
	for enemy in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var path_key := str(enemy.get_path())
		if saved_enemy_states.has(path_key):
			var state_data: Dictionary = saved_enemy_states[path_key]
			
			if state_data.get("is_defeated", false):
				enemy.queue_free()
			else:
				var saved_pos: Vector2 = state_data.get("position", enemy.position)
				enemy.position = saved_pos
				# Updates _last_position using set() to avoid wrong particle emissions
				enemy.set("_last_position", saved_pos)
				
	# Restore layers modified by other enemies
	if saved_consumed_tiles.size() > 0 and shared_void_layer != null:
		if shared_void_layer.has_method("consume_cells"):
			shared_void_layer.consume_cells(saved_consumed_tiles)


func _process(_delta: float) -> void:
	if _tracker_instance != self or shared_void_layer == null:
		return
		
	for enemy in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.get("state") == 3: 
			continue
			
		if shared_void_layer.has_method("coord_for") and shared_void_layer.has_method("get_neighbor_cell"):
			var coord: Vector2i = shared_void_layer.coord_for(enemy)
			var coords: Array[Vector2i] = [coord]
			
			for neighbor: int in _NEIGHBORS:
				coords.append(shared_void_layer.get_neighbor_cell(coord, neighbor))
				
			for c: Vector2i in coords:
				if not pending_consumed_tiles.has(c) and not saved_consumed_tiles.has(c):
					pending_consumed_tiles.append(c)


func activate() -> void:
	for c: Vector2i in pending_consumed_tiles:
		if not saved_consumed_tiles.has(c):
			saved_consumed_tiles.append(c)
	pending_consumed_tiles.clear()
	
	for enemy: CharacterBody2D in persistent_enemies:
		var path_key := str(enemy.get_path())
		if is_instance_valid(enemy) and enemy.get("state") != 3:
			saved_enemy_states[path_key] = {
				"position": enemy.position,
				"is_defeated": false
			}
		else:
			saved_enemy_states[path_key] = {
				"position": Vector2.ZERO,
				"is_defeated": true
			}
			
	super.activate()
