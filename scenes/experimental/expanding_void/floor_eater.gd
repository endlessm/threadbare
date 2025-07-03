# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var layers_to_destroy: Array[TileMapLayer]
@export var directions_to_destroy: Array[TileSet.CellNeighbor] = [
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]
@export var void_layer: TileMapLayer
@export var terrain_set_id: int = 0
@export var void_terrain_name: String = "Void"
@export var starting_point: Marker2D
@export var player: Player

@export_range(0.1, 2, 0.01, "suffix:seconds") var interval = 1.0

var _void_terrain_index: int = -1

var _timer: Timer

# The next tiles that will be eaten
var _frontier: Array[Vector2i]


func _ready() -> void:
	# Simplifies matching up tile coordinates; could be relaxed later
	for layer in layers_to_destroy:
		assert(layer.global_position == void_layer.global_position)
		assert(layer.tile_set == void_layer.tile_set)

	assert(void_layer.tile_set.get_terrain_sets_count() > terrain_set_id)
	for index: int in range(0, void_layer.tile_set.get_terrains_count(terrain_set_id)):
		var name: String = void_layer.tile_set.get_terrain_name(terrain_set_id, index)
		if name == void_terrain_name:
			_void_terrain_index = index
			break
	assert(_void_terrain_index >= 0)

	_frontier = [void_layer.local_to_map(void_layer.to_local(starting_point.global_position))]

	_timer = Timer.new()
	_timer.timeout.connect(_on_timer_timeout)
	self.add_child(_timer)

	_timer.start(interval)


func _physics_process(_delta: float) -> void:
	if player.mode == Player.Mode.DEFEATED:
		return

	var n := player.get_slide_collision_count()
	for i in range(n):
		var collision := player.get_slide_collision(i)
		if void_layer.has_body_rid(collision.get_collider_rid()):
			player.mode = Player.Mode.DEFEATED
			await get_tree().create_timer(2.0).timeout
			SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)


func destroy() -> void:
	for layer: TileMapLayer in layers_to_destroy:
		layer.set_cells_terrain_connect(_frontier, terrain_set_id, -1)
	void_layer.set_cells_terrain_connect(_frontier, terrain_set_id, _void_terrain_index)


func replan() -> void:
	var new_frontier: Array[Vector2i]

	for tile: Vector2i in _frontier:
		for direction: TileSet.CellNeighbor in directions_to_destroy:
			var coord := void_layer.get_neighbor_cell(tile, direction)
			if coord in new_frontier:
				continue

			for layer: TileMapLayer in layers_to_destroy:
				var source_id := layer.get_cell_source_id(coord)
				if source_id != -1:
					new_frontier.append(coord)
					break

	_frontier = new_frontier


func _on_timer_timeout() -> void:
	destroy()
	replan()
	if not _frontier:
		_timer.stop()
