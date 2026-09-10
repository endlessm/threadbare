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

# Store everything including position, paths, and consumed tiles in a single dictionary 
# bound strictly to each enemy to prevent synchronization issues.
static var saved_enemy_states: Dictionary = {}

# Temporary dictionary to track tiles for each enemy individually.
var pending_consumed_tiles: Dictionary = {}
var _is_restoring: bool = false

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
		
	pending_consumed_tiles.clear()
		
	# Gather all saved tiles from all active enemies assigned to this checkpoint.
	var all_saved_tiles: Array[Vector2i] = []
	for path_key: String in saved_enemy_states:
		var data: Dictionary = saved_enemy_states[path_key]
		if data.has("tiles"):
			for c: Vector2i in data["tiles"]:
				if not all_saved_tiles.has(c):
					all_saved_tiles.append(c)
					
	# Consume the TileMap cells before placing the enemies to prevent visual glitches.
	if all_saved_tiles.size() > 0 and shared_void_layer != null:
		if shared_void_layer.has_method("consume_cells"):
			shared_void_layer.consume_cells(all_saved_tiles)
			
	_is_restoring = true
	call_deferred("_restore_enemies")


func _restore_enemies() -> void:
	for enemy: CharacterBody2D in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var path_key := str(enemy.get_path())
		if saved_enemy_states.has(path_key):
			var data: Dictionary = saved_enemy_states[path_key]
			
			if data.get("is_defeated", false):
				enemy.queue_free()
				continue
				
			# Restore the global position for the world.
			enemy.global_position = data["position"]
			
			# Inject the local position instead of the global one.
			if "_last_position" in enemy:
				enemy.set("_last_position", enemy.position)
				
			if data.has("state"):
				enemy.set("state", data["state"])
			
			var path_behavior: Node = enemy.get_node_or_null("%PathWalkBehavior")
			if path_behavior and data.has("path_behavior"):
				var pb_data: Dictionary = data["path_behavior"]
				for prop: String in pb_data:
					path_behavior.set(prop, pb_data[prop])
			
			if data.get("is_guard", false):
				enemy.set("current_patrol_point_idx", data["current_idx"])
				enemy.set("previous_patrol_point_idx", data["prev_idx"])
				
				var movement: Node = enemy.get_node_or_null("%GuardMovement")
				if movement and movement.has_method("set_destination"):
					movement.set_destination(data["movement_dest"])
					
	_is_restoring = false


func _track_tiles() -> void:
	if Engine.is_editor_hint() or shared_void_layer == null or _is_restoring:
		return
		
	for enemy: CharacterBody2D in persistent_enemies:
		if not is_instance_valid(enemy):
			continue
			
		var is_guard: bool = "current_patrol_point_idx" in enemy
		var raw_state: Variant = enemy.get("state")
		var state: int = raw_state if raw_state != null else -1
		
		if not is_guard and state == 3:
			continue
			
		if shared_void_layer.has_method("coord_for") and shared_void_layer.has_method("get_neighbor_cell"):
			var coord: Vector2i = shared_void_layer.coord_for(enemy)
			var coords: Array[Vector2i] = [coord]
			
			for neighbor: int in _NEIGHBORS:
				coords.append(shared_void_layer.get_neighbor_cell(coord, neighbor))
				
			if not pending_consumed_tiles.has(enemy):
				pending_consumed_tiles[enemy] = []
				
			for c: Vector2i in coords:
				if not pending_consumed_tiles[enemy].has(c):
					pending_consumed_tiles[enemy].append(c)


func _process(_delta: float) -> void:
	_track_tiles()


func _physics_process(_delta: float) -> void:
	_track_tiles()


func activate() -> void:
	if _is_restoring:
		super.activate()
		return
		
	# Make a copy of the old states before clearing them to retain previous progress.
	var old_states: Dictionary = saved_enemy_states.duplicate()
	saved_enemy_states.clear()
	
	for enemy: CharacterBody2D in persistent_enemies:
		var path_key := str(enemy.get_path())
		if not is_instance_valid(enemy):
			continue
			
		var is_guard: bool = "current_patrol_point_idx" in enemy
		var raw_state: Variant = enemy.get("state")
		var state: int = raw_state if raw_state != null else -1
		var is_defeated: bool = not is_guard and state == 3
		
		# Retrieve the tiles that the enemy had already destroyed in past lives.
		var old_tiles: Array = []
		if old_states.has(path_key):
			old_tiles = old_states[path_key].get("tiles", [])
			
		# Add the newly destroyed tiles from the current run.
		var new_tiles: Array = pending_consumed_tiles.get(enemy, [])
		var combined_tiles: Array = old_tiles.duplicate()
		
		for c: Vector2i in new_tiles:
			if not combined_tiles.has(c):
				combined_tiles.append(c)
		
		# Save the complete snapshot for this specific enemy.
		var enemy_data := {
			"position": enemy.global_position,
			"is_guard": is_guard,
			"is_defeated": is_defeated,
			"state": state,
			"tiles": combined_tiles
		}
		
		var path_behavior: Node = enemy.get_node_or_null("%PathWalkBehavior")
		if path_behavior:
			var pb_data := {}
			for prop: String in ["progress", "progress_ratio", "current_point_index", "current_point", "target_position"]:
				if prop in path_behavior:
					pb_data[prop] = path_behavior.get(prop)
			enemy_data["path_behavior"] = pb_data
		
		if is_guard and not is_defeated:
			var movement: Node = enemy.get_node_or_null("%GuardMovement")
			var dest: Vector2 = movement.get("destination") if movement else enemy.global_position
			
			enemy_data["current_idx"] = enemy.get("current_patrol_point_idx")
			enemy_data["prev_idx"] = enemy.get("previous_patrol_point_idx")
			enemy_data["movement_dest"] = dest
			
		saved_enemy_states[path_key] = enemy_data
		
	# Clear the temporary list once the state is securely saved.
	pending_consumed_tiles.clear()
			
	super.activate()
