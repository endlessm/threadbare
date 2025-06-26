# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

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
@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

var speed = 192

var _moving: bool = false


func _ready() -> void:
	# Simplifies matching up tile coordinates; could be relaxed later
	assert(floor_layer.global_position == void_layer.global_position)


func start(_dummy: bool) -> void:
	_moving = true
	animated_sprite_2d.play(&"walk")


func _physics_process(_delta: float) -> void:
	if not _moving:
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(player.global_position) * speed
	move_and_slide()


func _process(_delta: float) -> void:
	if not _moving:
		return

	var coord := floor_layer.local_to_map(floor_layer.to_local(global_position))
	var coords: Array[Vector2i] = [coord]
	for neighbor: int in NEIGHBORS:
		coords.append(floor_layer.get_neighbor_cell(coord, neighbor))

	for i in range(coords.size() - 1, -1, -1):
		var c: Vector2i = coords[i]
		var source_id := floor_layer.get_cell_source_id(c)
		if source_id == -1:
			coords.remove_at(i)

	if coords:
		floor_layer.set_cells_terrain_connect(coords, TERRAIN_SET, -1)
		void_layer.set_cells_terrain_connect(coords, TERRAIN_SET, VOID_TERRAIN)
