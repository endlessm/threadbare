# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Checkpoint
class_name CheckpointVoid
## A checkpoint that saves and restores the state of specific enemies and the void layer.
##
## This checkpoint extends the base Checkpoint functionality to track specific enemies 
## (like guards or void-spreading enemies) and prevents them, along with consumed tiles, 
## from resetting when the scene is reloaded.

static var saved_enemy_states: Dictionary = {}
static var saved_consumed_tiles: Array[Vector2i] = []
static var pending_consumed_tiles: Array[Vector2i] = []
static var _tracker_instance: Node = null

## Specific enemies that should retain their position and state across scene reloads.
@export var persistent_enemies: Array[CharacterBody2D]

## The tilemap layer that is being consumed by the void.
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
		
	# Designate a single instance as the tracker to avoid repeating calculations
	# when multiple checkpoints exist in the same level.
	if _tracker_instance == null or not is_instance_valid(_tracker_instance):
		_tracker_instance = self
		pending_consumed_tiles.clear()
		
	if saved_consumed_tiles.size() > 0 and shared_void_layer != null:
		if shared_void_layer.has_method("consume_cells"):
			shared_void_layer.consume_cells(saved_consumed_tiles)
			
	# Deferring this call ensures that any initialization in the enemy's _ready
	# function finishes before overwriting its variables.
	call_deferred("_restore_enemies")


func _restore_enemies() -> void:
	for enemy: CharacterBody2D in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var path_key := str(enemy.get_path())
		if saved_enemy_states.has(path_key):
			var data: Dictionary = saved_enemy_states[path_key]
			
			# Only the void-spreading enemies will trigger this, since guards are never saved as defeated.
			if data.get("is_defeated", false):
				enemy.queue_free()
				continue
				
			enemy.global_position = data["position"]
			
			# Prevent a massive particle burst upon reload by syncing the last recorded position.
			if "_last_position" in enemy:
				enemy.set("_last_position", data["position"])
			
			# Restore specific patrol variables if the enemy acts as a guard.
			if data.get("is_guard", false):
				enemy.set("current_patrol_point_idx", data["current_idx"])
				enemy.set("previous_patrol_point_idx", data["prev_idx"])
				enemy.set("state", data["state"])
				
				var movement: Node = enemy.get_node_or_null("%GuardMovement")
				if movement and movement.has_method("set_destination"):
					movement.set_destination(data["movement_dest"])


func _process(_delta: float) -> void:
	if _tracker_instance != self or shared_void_layer == null:
		return
		
	for enemy: CharacterBody2D in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var is_guard: bool = "current_patrol_point_idx" in enemy
		var state: int = enemy.get("state")
		
		# Ignore defeated enemies. VoidSpreadingEnemy uses state 3 for DEFEATED.
		# Guards do not have a defeated state, so we skip this check for them.
		if not is_guard and state == 3:
			continue
			
		# Replicate the void calculation logic for living enemies.
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
		if not is_instance_valid(enemy):
			continue
			
		var is_guard: bool = "current_patrol_point_idx" in enemy
		var state: int = enemy.get("state")
		
		# Guards are never defeated, only void-spreading enemies (state 3) can be.
		var is_defeated: bool = not is_guard and state == 3
		
		# Base dictionary data shared across all supported enemy types.
		var enemy_data := {
			"position": enemy.global_position,
			"is_guard": is_guard,
			"is_defeated": is_defeated
		}
		
		# Save additional patrol data if the enemy acts as a guard.
		if is_guard and not is_defeated:
			var movement: Node = enemy.get_node_or_null("%GuardMovement")
			var dest: Vector2 = movement.get("destination") if movement else enemy.global_position
			
			enemy_data["current_idx"] = enemy.get("current_patrol_point_idx")
			enemy_data["prev_idx"] = enemy.get("previous_patrol_point_idx")
			enemy_data["state"] = state
			enemy_data["movement_dest"] = dest
			
		saved_enemy_states[path_key] = enemy_data
			
	super.activate()
