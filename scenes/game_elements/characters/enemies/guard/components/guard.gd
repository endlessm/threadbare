# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Guard extends CharacterBody2D
## Enemy type that patrols along a path and raises an alert if the player is detected.

## Emitted when the player is detected.
signal player_detected(player: Player)

enum State {
	## Going along the path.
	PATROLLING,
	## Waiting in path corners.
	WAITING,
	## Player is in sight.
	## If player stays in sight, after some time it will become alerted.
	## If player gets out of sight, the guard goes to investigate where the player was last seen.
	DETECTING,
	## Player was detected.
	ALERTED,
	## Player was in sight, going to the last point where the player was seen.
	INVESTIGATING,
	## Lost track of player, walking back to the patrol path.
	RETURNING,
}

const DEFAULT_SPRITE_FRAMES = preload("uid://ovu5wqo15s5g")

@export_category("Appearance")
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames
@export_category("Sounds")
## Sound played when a guard's [enum State] enters DETECTING or ALERTED.
@export var alerted_sound_stream: AudioStream:
	set = _set_alerted_sound_stream
## Sound played when a guard's moving from one point to the next.
@export var footsteps_sound_stream: AudioStream:
	set = _set_footsteps_sound_stream
## Sound played continuously.
@export var idle_sound_stream: AudioStream:
	set = _set_idle_sound_stream
## Sound played in bursts after the guard entered [enum State] ALERTED.
@export var alert_others_sound_stream: AudioStream:
	set = _set_alert_other_sound_stream

@export_category("Patrol")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Add/Edit Patrol Path") var _edit_patrol_path: Callable = edit_patrol_path
## The path the guard follows while patrolling.
@export var patrol_path: Path2D

## The wait time at each patrol point.
@export_range(0, 5, 0.1, "or_greater", "suffix:s") var wait_time: float = 1.0
## The speed at which the guard moves.
@export_range(20, 300, 5, "or_greater", "or_less", "suffix:m/s") var move_speed: float = 100.0

@export_category("Player Detection")
## Whether the player is instantly detected upon being seen.
@export var player_instantly_detected_on_sight: bool = false
## Time required to detect the player.
@export_range(0.1, 5, 0.1, "or_greater", "suffix:s") var time_to_detect_player: float = 1.0
## Scale factor for the detection area.
@export_range(0.1, 5, 0.1, "or_greater", "or_less") var detection_area_scale: float = 1.0:
	set(new_value):
		detection_area_scale = new_value
		if detection_area:
			detection_area.scale = Vector2.ONE * detection_area_scale

@export_category("Debug")

## Toggles visibility of debug info.
@export var show_debug_info: bool = false

## Breadcrumbs for tracking guards position while investigating, before
## returning to patrol, the guard walks through all these positions.
var breadcrumbs: Array[Vector2] = []
## Current state of the guard.
var state: State:
	set = _set_state

var _state_after_waiting: State

# The player that's being detected.
var _player: Player

# While this time is greater than 0, the guard won't move.
var _waiting_time_left: float

# Mark the global position in which the player was last seen.
var _last_seen: Marker2D

var _returning_path: Path2D

## Area that represents the sight of the guard. If a player is in this area
## and there are no walls in between detected by [member sight_ray_cast], it
## means the player is in sight.
@onready var detection_area: Area2D = %DetectionArea
## Progress bar that indicates how aware the guard is of the player, if it
## is completely filled, [signal player_detected] is triggered.
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
## RayCast used to detect if the sight to a position is blocked.
@onready var sight_ray_cast: RayCast2D = %SightRayCast
## Control to hold debug info that can be toggled on or off.
@onready var debug_info: Label = %DebugInfo
## Behavior to walk along a path.
@onready var patrolling_behavior: PathWalkBehavior = %PatrollingBehavior
## TODO document
@onready var investigating_behavior: FollowWalkBehavior = %InvestigatingBehavior
## TODO document
@onready var returning_behavior: PathWalkBehavior = %ReturningBehavior

## Reference to the node controlling the AnimationPlayer for walking / being idle,
## so it can be disabled to play the alerted animation.
@onready
# gdlint:ignore = max-line-length
var character_animation_player_behavior: CharacterAnimationPlayerBehavior = %CharacterAnimationPlayerBehavior

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var _alert_sound: AudioStreamPlayer = %AlertSound
@onready var _foot_sound: AudioStreamPlayer2D = %FootSound
@onready var _fire_sound: AudioStreamPlayer2D = %FireSound
@onready var _torch_hit_sound: AudioStreamPlayer2D = %TorchHitSound


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not sprite_frames:
		warnings.push_back("sprite_frames must be set.")

	for required_animation: StringName in [&"alerted", &"idle", &"walk"]:
		if sprite_frames and not sprite_frames.has_animation(required_animation):
			warnings.push_back(
				"sprite_frames is missing the following animation: %s" % required_animation
			)

	return warnings


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Player awareness is configured and started empty.
		if player_awareness:
			player_awareness.max_value = time_to_detect_player
			player_awareness.value = 0.0

		# Dynamically add a node to mark the global position in which the player was last seen.
		_last_seen = Marker2D.new()
		add_sibling.call_deferred(_last_seen)
		tree_exiting.connect(func() -> void: _last_seen.queue_free())

		# Dynamically add a path for returning.
		_returning_path = Path2D.new()
		add_sibling.call_deferred(_returning_path)
		tree_exiting.connect(func() -> void: _returning_path.queue_free())

		investigating_behavior.speeds.walk_speed = move_speed
		investigating_behavior.target = _last_seen
		returning_behavior.speeds.walk_speed = move_speed
		if patrol_path:
			patrolling_behavior.speeds.walk_speed = move_speed
			patrolling_behavior.walking_path = patrol_path
		else:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED

		#if wait_time:
		#_waiting_time_left = wait_time
		#state = State.WAITING
		#else:
		#state = State.PATROLLING
		state = State.PATROLLING

	_set_sprite_frames(sprite_frames)

	if detection_area:
		detection_area.scale = Vector2.ONE * detection_area_scale


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_debug_info()

	if state != State.ALERTED:
		_update_player_awareness(delta)

	match state:
		State.WAITING:
			# TODO: what is setting this?
			velocity = Vector2.ZERO
			if _waiting_time_left <= 0.0:
				state = _state_after_waiting
			else:
				_waiting_time_left -= delta


## Changes how PlayerAwareness looks to reflect how close is the player to
## being detected
func _update_player_awareness(delta: float) -> void:
	var player_in_sight := _player and not _is_sight_to_point_blocked(_player.global_position)

	player_awareness.value = move_toward(
		player_awareness.value, player_awareness.max_value if player_in_sight else 0.0, delta
	)
	player_awareness.visible = player_awareness.ratio > 0.0
	player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)

	if player_awareness.ratio >= 1.0:
		state = State.ALERTED
		player_detected.emit(_player)


func _update_debug_info() -> void:
	debug_info.visible = show_debug_info
	if not debug_info.visible:
		return
	debug_info.text = "state: %s\n" % State.keys()[state]
	match state:
		State.PATROLLING:
			var offset := patrolling_behavior.get_closest_offset_to_character()
			debug_info.text += "offset: %.2f\n" % offset
		State.WAITING:
			debug_info.text += "time left: %.2f\n" % _waiting_time_left
		State.DETECTING:
			var time_left := player_awareness.max_value - player_awareness.value
			debug_info.text += "time left: %.2f\n" % time_left
		State.INVESTIGATING:
			var distance := global_position.distance_to(
				investigating_behavior.target.global_position
			)
			debug_info.text += "distance: %.2f\n" % distance
		State.RETURNING:
			var distance := (
				_returning_path.curve.get_baked_length()
				- _returning_path.curve.get_closest_offset(global_position)
			)
			debug_info.text += "distance: %.2f\n" % distance


func _consume_breadcrumbs() -> Array[Vector2]:
	var new_breadcrumbs: Array[Vector2] = []
	var closest_offset := _returning_path.curve.get_closest_offset(global_position)
	for idx in range(_returning_path.curve.point_count):
		var point_position := _returning_path.curve.get_point_position(idx)
		if _returning_path.curve.get_closest_offset(point_position) < closest_offset:
			continue
		new_breadcrumbs.push_back(point_position)
	return new_breadcrumbs


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	match state:
		State.RETURNING:
			breadcrumbs = _consume_breadcrumbs()

	match new_state:
		State.PATROLLING:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			investigating_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			returning_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			breadcrumbs.clear()
		State.WAITING:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			investigating_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			returning_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			# TODO needed?
			velocity = Vector2.ZERO
		State.DETECTING:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			investigating_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			returning_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			# TODO needed?
			velocity = Vector2.ZERO
			if not _alert_sound.playing:
				_alert_sound.play()
		State.ALERTED:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			investigating_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			returning_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			character_animation_player_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			if not _alert_sound.playing:
				_alert_sound.play()
			animation_player.play(&"alerted")
			player_awareness.ratio = 1.0
			player_awareness.tint_progress = Color.RED
			player_awareness.visible = true
		State.INVESTIGATING:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			investigating_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			returning_behavior.process_mode = Node.PROCESS_MODE_DISABLED
		State.RETURNING:
			patrolling_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			investigating_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			returning_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			_returning_path.curve = Curve2D.new()
			breadcrumbs.push_front(global_position)
			for b in breadcrumbs:
				_returning_path.curve.add_point(b)
			returning_behavior.walking_path = _returning_path

	# Uncomment to debug the state transitions:
	if name == "Guard2-GoingInCircles":
		print("%-15s → %-15s" % [State.keys()[state], State.keys()[new_state]])
	state = new_state


## Checks if a straight line can be traced from the Guard to a certain point.
## It returns true if the path to the point is free of walls.
## Note: it only detects sight_occluders collisions, not wall collisions, this
## is so water doesn't block sight.
func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()


static func _editor_interface() -> Object:
	# TODO: Workaround for https://github.com/godotengine/godot/issues/91713
	# Referencing [class EditorInterface] in scripts that don't run in the editor
	# fails to load the script with a parse error.
	return Engine.get_singleton("EditorInterface")


## Function used for a tool button that either selects the current patrol_path
## in the editor, or creates a new one
func edit_patrol_path() -> void:
	if not Engine.is_editor_hint():
		return

	var editor_interface := _editor_interface()

	if patrol_path:
		editor_interface.edit_node.call_deferred(patrol_path)
	else:
		var new_patrol_path: Path2D = Path2D.new()
		patrol_path = new_patrol_path
		get_parent().add_child(patrol_path)
		patrol_path.owner = owner
		patrol_path.global_position = global_position
		var patrol_path_curve: Curve2D = Curve2D.new()
		patrol_path.curve = patrol_path_curve
		patrol_path.name = "%s-PatrolPath" % name
		patrol_path_curve.add_point(Vector2.ZERO)
		patrol_path_curve.add_point(Vector2.RIGHT * 150.0)
		editor_interface.edit_node.call_deferred(patrol_path)


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	update_configuration_warnings()


func _set_alerted_sound_stream(new_value: AudioStream) -> void:
	alerted_sound_stream = new_value
	if not is_node_ready():
		await ready
	_alert_sound.stream = new_value


func _set_footsteps_sound_stream(new_value: AudioStream) -> void:
	footsteps_sound_stream = new_value
	if not is_node_ready():
		await ready
	_foot_sound.stream = new_value


func _set_idle_sound_stream(new_value: AudioStream) -> void:
	idle_sound_stream = new_value
	if not is_node_ready():
		await ready
	_fire_sound.stream = new_value


func _set_alert_other_sound_stream(new_value: AudioStream) -> void:
	alert_others_sound_stream = new_value
	if not is_node_ready():
		await ready
	_torch_hit_sound.stream = new_value


func _on_instant_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	state = State.ALERTED
	player_detected.emit(body as Player)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_player = body as Player
	if _is_sight_to_point_blocked(body.global_position):
		return
	if player_instantly_detected_on_sight:
		state = State.ALERTED
		player_detected.emit(_player)
	else:
		if state == State.INVESTIGATING:
			breadcrumbs.push_front(global_position)
		else:
			state = State.DETECTING


func _on_detection_area_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_player = null
	# if not _is_sight_to_point_blocked(body.global_position):
	_last_seen.global_position = body.global_position
	investigating_behavior.target = _last_seen
	if state == State.DETECTING:
		state = State.INVESTIGATING


func _wait_patrolling() -> void:
	_waiting_time_left = wait_time
	_state_after_waiting = State.PATROLLING
	state = State.WAITING


func _on_patrolling_behavior_pointy_path_reached() -> void:
	if wait_time:
		_wait_patrolling()


func _on_patrolling_behavior_got_stuck() -> void:
	if wait_time:
		_wait_patrolling()


func _on_investigating_behavior_target_reached_changed(is_reached: bool) -> void:
	if not is_reached:
		return
	if breadcrumbs.is_empty():
		_state_after_waiting = State.PATROLLING
	else:
		_state_after_waiting = State.RETURNING
	_waiting_time_left = wait_time
	state = State.WAITING


func _on_returning_behavior_ending_reached() -> void:
	state = State.PATROLLING


func _on_returning_behavior_pointy_path_reached() -> void:
	breadcrumbs = _consume_breadcrumbs()


func _on_investigating_behavior_got_stuck() -> void:
	state = State.RETURNING
