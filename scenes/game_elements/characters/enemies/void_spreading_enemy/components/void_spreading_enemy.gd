# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CharacterBody2D
## An enemy that patrols or chases the player, spreading Void as it moves

## The state of this enemy
enum State {
	## The void is lying in wait
	IDLE,
	## The void is chasing the player
	CHASING,
	## The void has engulfed the player
	CAUGHT,
	## The void has been defeated
	DEFEATED,
}

const NEIGHBORS := [
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
]

const IDLE_EMIT_DISTANCE := sqrt(2 * (64.0 ** 2))

## The layer that covers the visible world when tiles are placed. If unset, the enemy will not
## spread the void or consume props.
@export var void_layer: TileMapCover:
	set = set_void_layer

## The path that the enemy patrols when [member state] is IDLE. If unset, the enemy will not move
## when idle.
@export var idle_patrol_path: Path2D:
	set = _set_idle_patrol_path

## [GPUParticles2D] scene to spawn when tiles are consumed, or after travelling some distance
## without consuming anything (so that the enemy remains visible when patrolling an already-covered
## area)
@export var void_particles: PackedScene

var node_to_follow: Node2D:
	set = _set_node_to_follow

var state := State.IDLE:
	set = _set_state

var _last_position: Vector2
var _distance_since_emit: float = 0.0
var _live_particles: int = 0

@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior
@onready var follow_walk_behavior: NavigationFollowWalkBehavior = %NavigationFollowWalkBehavior
@onready var alert_animation: AnimationPlayer = %AlertAnimation
@onready var particles_canvas_group: CanvasGroup = %ParticlesCanvasGroup
@onready var idle_sfx: AudioStreamPlayer2D = %IdleSFX
@onready var chasing_sfx: AudioStreamPlayer2D = %ChasingSFX
@onready var caught_sfx: AudioStreamPlayer2D = %CaughtSFX
@onready var defeated_sfx: AudioStreamPlayer2D = %DefeatedSFX


#region setters
func set_void_layer(new_layer: TileMapCover) -> void:
	void_layer = new_layer
	update_configuration_warnings()


func _set_idle_patrol_path(new_path: Path2D) -> void:
	idle_patrol_path = new_path
	if path_walk_behavior:
		path_walk_behavior.walking_path = idle_patrol_path
	update_configuration_warnings()


func _set_node_to_follow(new_node_to_follow: Node2D) -> void:
	node_to_follow = new_node_to_follow
	if follow_walk_behavior:
		follow_walk_behavior.target = node_to_follow


func _stop_positional_sfx() -> void:
	idle_sfx.stop()
	chasing_sfx.stop()
	caught_sfx.stop()


func _set_state(new_state: State) -> void:
	state = new_state

	if not is_node_ready() or Engine.is_editor_hint():
		return

	_stop_positional_sfx()

	match state:
		State.IDLE:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			idle_sfx.play()
		State.CHASING:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			alert_animation.play(&"alert")
			chasing_sfx.play()
		State.CAUGHT:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			caught_sfx.play()
		State.DEFEATED:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED


#endregion


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not void_layer:
		warnings.append("Void Layer not set. The enemy cannot cover the world or consume props")

	if not idle_patrol_path:
		warnings.append("Idle Patrol Path not set. The enemy will be invisible when idle")

	return warnings


func _ready() -> void:
	idle_patrol_path = idle_patrol_path
	state = state
	_last_position = position
	_init_persistence()

	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)


func start(detected_node: Node2D) -> void:
	node_to_follow = detected_node
	state = State.CHASING


func defeat() -> void:
	state = State.DEFEATED
	defeated_sfx.reparent(get_parent())
	defeated_sfx.finished.connect(defeated_sfx.queue_free)
	defeated_sfx.play()

	if _live_particles == 0:
		queue_free()
	# else wait for `_emit_particles` to free this node after all particles are finished.


func _process(_delta: float) -> void:
	if state == State.DEFEATED:
		return
	_distance_since_emit += (position - _last_position).length()
	_last_position = position

	if _consume_tiles() or _distance_since_emit >= IDLE_EMIT_DISTANCE:
		_emit_particles()


func _consume_tiles() -> bool:
	if not void_layer:
		return false

	var coord := void_layer.coord_for(self)
	var coords: Array[Vector2i] = [coord]
	# TODO: this looks bad because as soon as the enemy enters the left-hand
	# edge of tile (x, y) they destroy tile (x+1, y).
	# It would look better if it was based on distance to the centre of the
	# enemy/how much of the area of destruction covers the target tile.
	for neighbor: int in NEIGHBORS:
		coords.append(void_layer.get_neighbor_cell(coord, neighbor))

	return void_layer.consume_cells(coords)


func _emit_particles() -> void:
	_distance_since_emit = 0

	var particles: GPUParticles2D = void_particles.instantiate()
	particles.emitting = true
	particles_canvas_group.add_child(particles)
	_live_particles += 1

	await particles.finished

	particles.queue_free()
	_live_particles -= 1
	if state == State.DEFEATED and _live_particles == 0:
		queue_free()


func _on_player_capture_area_body_entered(body: Node2D) -> void:
	if body is not Player:
		return

	state = State.CAUGHT

	var player := body as Player
	player.defeat(true)


## Hooks into the global scene state to monitor for spawn point updates.
func _init_persistence() -> void:
	if GameState.scene == null or not "facts" in GameState.scene:
		return
		
	if not GameState.scene.changed.is_connected(_on_checkpoint_activated):
		GameState.scene.changed.connect(_on_checkpoint_activated)
			
	_load_state()


## Packages the enemy's positional data and path progress into the global facts dictionary.
## Verifies the persistence flag of the active checkpoint before saving.
func _on_checkpoint_activated() -> void:
	var spawn_path: NodePath = GameState.scene.spawn_point
	if spawn_path.is_empty(): 
		return
	
	var node: Node = get_tree().current_scene.get_node_or_null(spawn_path)
	var checkpoint: Node = node
	
	while checkpoint and not checkpoint is Checkpoint:
		checkpoint = checkpoint.get_parent()
		
	if not checkpoint or not checkpoint.get("save_void_and_enemies"):
		return 
		
	var save_key := str(get_path())
	var data := {
		"position": global_position,
		"last_position": _last_position,
		"state": state
	}
	
	if path_walk_behavior:
		data["path_progress"] = path_walk_behavior.get("progress_ratio")
		
	GameState.scene.facts[save_key] = data


## Restores the enemy to its exact state from the previous save.
## Overrides the internal last_position variable to prevent massive particle bursts caused by global teleportation.
func _load_state() -> void:
	var save_key := str(get_path())
	if GameState.scene.facts.has(save_key):
		var data: Dictionary = GameState.scene.facts[save_key]
		
		global_position = data["position"]
		_last_position = data["last_position"]
		state = data["state"]
		
		if path_walk_behavior and data.has("path_progress"):
			path_walk_behavior.set("progress_ratio", data["path_progress"])
