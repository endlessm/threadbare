# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

const TERRAIN_SET: int = 0
const VOID_TERRAIN: int = 8
const NEIGHBORS := [
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

@export var layers_to_destroy: Array[TileMapLayer]
@export var void_layer: TileMapLayer
@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var navigation_agent: NavigationAgent2D
@export var destroyable_nodes: Node2D

@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0

var _moving: bool = false
var _next_update: float = 1.0


func _ready() -> void:
	# Simplifies matching up tile coordinates; could be relaxed later
	for layer in layers_to_destroy:
		assert(layer.global_position == void_layer.global_position)


func start(_dummy: bool) -> void:
	_moving = true
	animated_sprite_2d.play(&"walk")
	navigation_agent.target_position = player.global_position


func _physics_process(delta: float) -> void:
	if not _moving:
		velocity = Vector2.ZERO
		return

	if not navigation_agent.is_target_reachable():
		# We made it to safety!
		animated_sprite_2d.play(&"alerted")
	else:
		animated_sprite_2d.play(&"walk")

	_next_update -= delta
	if navigation_agent.is_navigation_finished() or _next_update < 0:
		_next_update = 1.0
		navigation_agent.target_position = player.global_position
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var running := navigation_agent.distance_to_target() > (64 * 3)
	var speed = run_speed if running else walk_speed
	# TODO: smoothly change between running & walking speed?
	velocity = current_agent_position.direction_to(next_path_position) * speed
	move_and_slide()


func _has_tile(coord: Vector2i) -> bool:
	for layer in layers_to_destroy:
		var source_id := layer.get_cell_source_id(coord)
		if source_id != -1:
			return true

	return false


func _process(_delta: float) -> void:
	if not _moving:
		return

	var dead := false
	var coord := void_layer.local_to_map(void_layer.to_local(global_position))
	var coords: Array[Vector2i] = [coord]
	for neighbor: int in NEIGHBORS:
		coords.append(void_layer.get_neighbor_cell(coord, neighbor))

	for i in range(coords.size() - 1, -1, -1):
		var c: Vector2i = coords[i]
		if not _has_tile(c):
			coords.remove_at(i)
		else:
			var player_coords := void_layer.local_to_map(
				void_layer.to_local(player.global_position)
			)
			if c == player_coords:
				dead = true

			for node: Node2D in destroyable_nodes.get_children():
				var node_coords := void_layer.local_to_map(
					void_layer.to_local(node.global_position)
				)
				if c == node_coords:
					node.queue_free()

	if coords:
		for layer in layers_to_destroy:
			layer.set_cells_terrain_connect(coords, TERRAIN_SET, -1)
		void_layer.set_cells_terrain_connect(coords, TERRAIN_SET, VOID_TERRAIN)

	if dead:
		_moving = false
		animated_sprite_2d.play(&"alerted")
		player.mode = Player.Mode.DEFEATED
		var tween := create_tween()
		tween.tween_property(player, "scale", Vector2.ZERO, 2.0)
		await get_tree().create_timer(2.0).timeout
		SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
