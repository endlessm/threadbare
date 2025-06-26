# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const TERRAIN_SET: int = 0
const VOID_TERRAIN: int = 8
const NEIGHBORS := [
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

@export var floor_layer: TileMapLayer
@export var void_layer: TileMapLayer
@export var starting_point: Marker2D
@export var player: Player

@export_range(0.1, 2, 0.01, "suffix:seconds") var speed = 1.0

var _timer: Timer

# The next tiles that will be eaten
var _frontier: Array[Vector2i]


func _ready() -> void:
	# Simplifies matching up tile coordinates; could be relaxed later
	assert(floor_layer.global_position == void_layer.global_position)

	_frontier = [floor_layer.local_to_map(floor_layer.to_local(starting_point.global_position))]

	_timer = Timer.new()
	_timer.timeout.connect(_on_timer_timeout)
	self.add_child(_timer)


func start(_dummy: bool) -> void:
	# TODO: the _dummy parameter is needed because Level has no 0-arg signal.
	# We could instead have this node extend Toggleable so that it can be made a switch target.
	# Or connect the signal in code.
	_timer.start(speed)


func _on_timer_timeout() -> void:
	var new_frontier: Array[Vector2i]
	var dead := false
	floor_layer.set_cells_terrain_connect(_frontier, TERRAIN_SET, -1)
	void_layer.set_cells_terrain_connect(_frontier, TERRAIN_SET, VOID_TERRAIN)

	for tile: Vector2i in _frontier:
		var player_coords := floor_layer.local_to_map(floor_layer.to_local(player.global_position))
		if tile == player_coords:
			dead = true

		for direction: TileSet.CellNeighbor in NEIGHBORS:
			var coord := floor_layer.get_neighbor_cell(tile, direction)
			var source_id := floor_layer.get_cell_source_id(coord)
			if source_id != -1 and coord not in new_frontier:
				new_frontier.append(coord)

	_frontier = new_frontier
	if not _frontier:
		_timer.stop()

	if dead:
		player.mode = Player.Mode.DEFEATED
		await get_tree().create_timer(2.0).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
