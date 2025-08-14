# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D

const TERRAIN_SET: int = 0
const VOID_TERRAIN: int = 9
const NEIGHBORS := [
	# TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	# TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	# TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	# TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

@export var void_layer: TileMapCover
@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var particles: GPUParticles2D
@export var navigation_agent: NavigationAgent2D

@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0

var _moving: bool = false
var _update_interval: float = 10.0 / 60.0
var _next_update: float


func _ready() -> void:
	particles.emitting = false


func start(_dummy: Node2D) -> void:
	_moving = true
	particles.emitting = true
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
		_next_update = _update_interval
		navigation_agent.target_position = player.global_position
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var running := navigation_agent.distance_to_target() > (64 * 3)
	var speed := run_speed if running else walk_speed
	# TODO: smoothly change between running & walking speed?
	velocity = current_agent_position.direction_to(next_path_position) * speed
	move_and_slide()


func _process(_delta: float) -> void:
	if not _moving:
		return

	var coord := void_layer.coord_for(self)
	var coords: Array[Vector2i] = [coord]
	# TODO: this looks bad because as soon as the enemy enters the left-hand
	# edge of tile (x, y) they destroy tile (x+1, y).
	# It would look better if it was based on distance to the centre of the
	# enemy/how much of the area of destruction covers the target tile.
	for neighbor: int in NEIGHBORS:
		coords.append(void_layer.get_neighbor_cell(coord, neighbor))

	void_layer.consume_cells(coords)


func _on_player_capture_area_body_entered(body: Node2D) -> void:
	if body != player:
		return

	if not _moving:
		return

	_moving = false
	#particles.emitting = false
	animated_sprite_2d.play(&"alerted")
	player.mode = Player.Mode.DEFEATED
	var tween := create_tween()
	tween.tween_property(player, "scale", Vector2.ZERO, 2.0)
	await get_tree().create_timer(2.0).timeout
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
