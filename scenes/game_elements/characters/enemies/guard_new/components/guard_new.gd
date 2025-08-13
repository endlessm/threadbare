# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Character

enum State {
	## Going along the path.
	PATROLLING,
	## Player is in sight, it takes some time until the player is detected.
	DETECTING,
	## Player was detected.
	ALERTED,
	## Player was in sight, going to the last point where the player was seen.
	INVESTIGATING,
	## Lost track of player, walking back to the patrol path.
	RETURNING,
}

const GIVE_UP_TIME: float = 2.0
const TURN_SPEED: float = 10.0

@export var walking_path: Path2D:
	set = _set_walking_path

@export var node_to_follow: Node2D:
	set = _set_node_to_follow

@export_category("Target Detection")
## Time required to detect the target.
@export_range(0.1, 5, 0.1, "or_greater", "suffix:s") var detecting_time: float = 1.0

var state: State = State.PATROLLING:
	set = _change_state

var _detecting_timer: Timer = Timer.new()
var _investigating_giveup_timer: Timer = Timer.new()

@onready var can_walk_along_path: CanWalkAlongPath = %CanWalkAlongPath
@onready var can_follow_target: CanFollowTarget = %CanFollowTarget

## Area that represents the sight of the guard. If a player is in this area
## and there are no walls in between detected by [member sight_ray_cast], it
## means the player is in sight.
@onready var detection_area: Area2D = %DetectionArea

## Progress bar that indicates how aware the guard is of the player, if it
## is completely filled, [signal player_detected] is triggered.
@onready var player_awareness: TextureProgressBar = %PlayerAwareness


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	_set_walking_path(walking_path)
	_set_node_to_follow(node_to_follow)

	_detecting_timer.wait_time = detecting_time
	_detecting_timer.timeout.connect(_on_detected)
	_detecting_timer.one_shot = true
	add_child(_detecting_timer)
	_investigating_giveup_timer.wait_time = GIVE_UP_TIME
	_investigating_giveup_timer.timeout.connect(_give_up_investigation)
	_investigating_giveup_timer.one_shot = true
	add_child(_investigating_giveup_timer)
	player_awareness.modulate.a = 1.0
	player_awareness.value = 0.0


func _set_walking_path(new_walking_path: Path2D) -> void:
	walking_path = new_walking_path
	if not is_node_ready():
		return
	if walking_path:
		can_walk_along_path.walking_path = walking_path


func _set_node_to_follow(new_node_to_follow: Node2D) -> void:
	node_to_follow = new_node_to_follow
	if not is_node_ready():
		return
	if node_to_follow:
		can_follow_target.node_to_follow = node_to_follow


func _physics_process(delta: float) -> void:
	var target_angle: float = velocity.angle()
	detection_area.rotation = rotate_toward(
		detection_area.rotation, target_angle, delta * TURN_SPEED
	)
	match state:
		State.DETECTING:
			player_awareness.ratio = (
				(_detecting_timer.wait_time - _detecting_timer.time_left)
				/ _detecting_timer.wait_time
			)
			player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)
		State.PATROLLING, State.INVESTIGATING:  #, State.RETURNING:
			player_awareness.ratio = move_toward(player_awareness.ratio, 0.0, delta)
			player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)
			player_awareness.visible = player_awareness.value > 0.0


func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	var previous_state: State = state
	state = new_state

	match previous_state:
		State.DETECTING:
			_detecting_timer.stop()
		State.INVESTIGATING:
			_investigating_giveup_timer.stop()

	match new_state:
		State.PATROLLING:
			can_walk_along_path.process_mode = Node.PROCESS_MODE_INHERIT
			can_follow_target.process_mode = Node.PROCESS_MODE_DISABLED
		State.DETECTING:
			can_walk_along_path.process_mode = Node.PROCESS_MODE_DISABLED
			can_follow_target.process_mode = Node.PROCESS_MODE_DISABLED
			_detecting_timer.start()
			animated_sprite_2d.animation = &"idle"
			player_awareness.visible = true
		State.ALERTED:
			animated_sprite_2d.animation = &"alerted"
			player_awareness.ratio = 1.0
			player_awareness.tint_progress = Color.RED
		State.INVESTIGATING:
			can_walk_along_path.process_mode = Node.PROCESS_MODE_DISABLED
			can_follow_target.process_mode = Node.PROCESS_MODE_INHERIT
			_investigating_giveup_timer.start()


func _on_detection_area_body_entered(_body: Node2D) -> void:
	if state == State.PATROLLING:
		state = State.DETECTING
	elif state == State.INVESTIGATING:
		# Restart the timer, to continue investigating.
		_investigating_giveup_timer.start()


func _on_detection_area_body_exited(_body: Node2D) -> void:
	if state == State.DETECTING:
		state = State.INVESTIGATING


func _on_detected() -> void:
	state = State.ALERTED


func _give_up_investigation() -> void:
	state = State.PATROLLING
