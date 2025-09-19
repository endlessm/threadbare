# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CharacterBody2D
## @experimental

## The state of this enemy
enum State {
	## The void is lying in wait
	IDLE,
	## The void is chasing the player
	CHASING,
	## The void has engulfed the player
	CAUGHT,
}

const VOID_PARTICLES = preload(
	"res://scenes/quests/lore_quests/quest_002/1_void_runner/components/void_particles.tscn"
)
const TERRAIN_SET: int = 0
const VOID_TERRAIN: int = 9
const NEIGHBORS := [
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

@export var void_layer: TileMapCover

var player: Player:
	set = _set_player

var state := State.IDLE:
	set = _set_state

@onready var walk: NavigationFollowWalkBehavior = %NavigationFollowWalkBehavior


func _set_player(new_player: Player) -> void:
	player = new_player
	if walk:
		walk.target = player


func _set_state(new_state: State) -> void:
	state = new_state
	if walk:
		match state:
			State.IDLE:
				walk.process_mode = Node.PROCESS_MODE_DISABLED
			State.CHASING:
				walk.process_mode = Node.PROCESS_MODE_INHERIT


func _ready() -> void:
	player = player
	state = state


func start(detected_node: Node2D) -> void:
	if detected_node is Player:
		player = detected_node
		state = State.CHASING


func _process(_delta: float) -> void:
	if state == State.IDLE:
		return

	var coord := void_layer.coord_for(self)
	var coords: Array[Vector2i] = [coord]
	# TODO: this looks bad because as soon as the enemy enters the left-hand
	# edge of tile (x, y) they destroy tile (x+1, y).
	# It would look better if it was based on distance to the centre of the
	# enemy/how much of the area of destruction covers the target tile.
	for neighbor: int in NEIGHBORS:
		coords.append(void_layer.get_neighbor_cell(coord, neighbor))

	var consumed := void_layer.consume_cells(coords)
	if consumed:
		var particles := VOID_PARTICLES.instantiate()
		particles.emitting = true
		add_child(particles)
		await particles.finished
		particles.queue_free()


func _on_player_capture_area_body_entered(body: Node2D) -> void:
	if body != player:
		return

	if state != State.CHASING:
		return

	state = State.CAUGHT
	player.mode = Player.Mode.DEFEATED
	var tween := create_tween()
	tween.tween_property(player, "scale", Vector2.ZERO, 2.0)
	await get_tree().create_timer(2.0).timeout
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)
