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
	## Player is in sight, it takes some time until the player is detected.
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
@export var patrol_path: Path2D:
	set(new_value):
		patrol_path = new_value

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
## Enables movement in the editor for debugging.
@export var move_while_in_editor: bool = false
## Toggles visibility of debug info.
@export var show_debug_info: bool = false

## Index of the previous patrol point, -1 means that there isn't a previous
## point yet.
var previous_patrol_point_idx: int = -1
## Index of the current patrol point.
var current_patrol_point_idx: int = 0
## Last position in which the player was seen.
var last_seen_position: Vector2
## Breadcrumbs for tracking guards position while investigating, before
## returning to patrol, the guard walks through all these positions.
var breadcrumbs: Array[Vector2] = []
## Current state of the guard.
var state: State = State.PATROLLING:
	set = _set_state

# The player that's being detected.
var _player: Player

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

## Reference to the node controlling the AnimationPlayer for walking / being idle,
## so it can be disabled to play the alerted animation.
@onready
# gdlint:ignore = max-line-length
var character_animation_player_behavior: CharacterAnimationPlayerBehavior = %CharacterAnimationPlayerBehavior

## Handles the velocity and movement of the guard.
@onready var guard_movement: GuardMovement = %GuardMovement
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

	_set_sprite_frames(sprite_frames)

	if detection_area:
		detection_area.scale = Vector2.ONE * detection_area_scale

	# When the level starts, the guard is placed at the beginning of the
	# patrol path.
	if patrol_path:
		global_position = _patrol_point_position(0)

	guard_movement.destination_reached.connect(self._on_destination_reached)
	guard_movement.still_time_finished.connect(self._on_still_time_finished)
	guard_movement.path_blocked.connect(self._on_path_blocked)


func _process(delta: float) -> void:
	_update_debug_info()

	if Engine.is_editor_hint() and not move_while_in_editor:
		return

	_process_state()
	guard_movement.move()

	if state != State.ALERTED:
		_update_player_awareness(delta)

	_update_animation()


## Updates the guard's movement behavior based on its current state.
func _process_state() -> void:
	match state:
		State.PATROLLING:
			if patrol_path:
				var target_position: Vector2 = _patrol_point_position(current_patrol_point_idx)
				guard_movement.set_destination(target_position)
			else:
				guard_movement.stop_moving()
		State.INVESTIGATING:
			guard_movement.set_destination(last_seen_position)
		State.RETURNING:
			if not breadcrumbs.is_empty():
				var target_position: Vector2 = breadcrumbs.back()
				guard_movement.set_destination(target_position)
			else:
				state = State.PATROLLING
		State.ALERTED:
			guard_movement.stop_moving()


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


func _update_animation() -> void:
	if state == State.ALERTED:
		return

	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")


func _update_debug_info() -> void:
	debug_info.visible = show_debug_info
	if not debug_info.visible:
		return
	debug_info.text = ""
	debug_property("position")
	debug_value("state", State.keys()[state])
	debug_property("previous_patrol_point_idx")
	debug_property("current_patrol_point_idx")
	debug_value("time left", "%.2f" % guard_movement.still_time_left_in_seconds)
	debug_value("target point", guard_movement.destination)


## What happens when the guard reached the point it was walking towards
func _on_destination_reached() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time)
			_advance_target_patrol_point()
		State.INVESTIGATING:
			guard_movement.wait_seconds(wait_time)
		State.RETURNING:
			breadcrumbs.pop_back()


## What happens when the guard finished waiting on a point.
func _on_still_time_finished() -> void:
	match state:
		State.INVESTIGATING:
			state = State.RETURNING


## What happens if the guard cannot reach their destination because it got
## stuck with a collider.
func _on_path_blocked() -> void:
	match state:
		State.PATROLLING:
			guard_movement.wait_seconds(wait_time)
			# This check makes sure that if the guard is blocked on start,
			# they won't try to set an invalid patrol point as destination.
			if previous_patrol_point_idx > -1:
				var new_patrol_point: int = previous_patrol_point_idx
				previous_patrol_point_idx = current_patrol_point_idx
				current_patrol_point_idx = new_patrol_point
		State.INVESTIGATING:
			state = State.RETURNING
		State.RETURNING:
			if not breadcrumbs.is_empty():
				breadcrumbs.pop_back()


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.DETECTING:
			if not _alert_sound.playing:
				_alert_sound.play()
		State.ALERTED:
			character_animation_player_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			if not _alert_sound.playing:
				_alert_sound.play()
			animation_player.play(&"alerted")
			player_awareness.ratio = 1.0
			player_awareness.tint_progress = Color.RED
			player_awareness.visible = true
		State.INVESTIGATING:
			guard_movement.start_moving_now()
			breadcrumbs.push_back(global_position)


## Pass a property name as a parameter and it shows its name and its value
func debug_property(property_name: String) -> void:
	debug_value(property_name, get(property_name))


## Pass a value name and its value and it shows it on DebugInfo
func debug_value(value_name: String, value: Variant) -> void:
	debug_info.text += "%s: %s\n" % [value_name, value]


## Calculate and set the next point in the patrol path.
## The guard would circle back if the path is open, and go in rounds if the
## path is closed.
func _advance_target_patrol_point() -> void:
	if not patrol_path or not patrol_path.curve or _amount_of_patrol_points() < 2:
		return

	var new_patrol_point_idx: int

	if _is_patrol_path_closed():
		# amount of points - 1 is used here because in a closed path, the
		# last and first patrol points are the same. So, this lets us skip
		# that repeated point and go for the first one that is different
		new_patrol_point_idx = (current_patrol_point_idx + 1) % (_amount_of_patrol_points() - 1)
	else:
		var at_last_point: bool = current_patrol_point_idx == (_amount_of_patrol_points() - 1)
		var at_first_point: bool = current_patrol_point_idx == 0
		var going_backwards_in_path: bool = previous_patrol_point_idx > current_patrol_point_idx
		if at_last_point:
			# When reaching the end of the path, it starts walking back
			new_patrol_point_idx = current_patrol_point_idx - 1
		elif at_first_point:
			# If it's at first point is either because it was walking back
			# or because it's the first time it will move, in any case, it moves
			# forward
			new_patrol_point_idx = current_patrol_point_idx + 1
		elif going_backwards_in_path:
			new_patrol_point_idx = current_patrol_point_idx - 1
		else:
			new_patrol_point_idx = current_patrol_point_idx + 1

	previous_patrol_point_idx = current_patrol_point_idx
	current_patrol_point_idx = new_patrol_point_idx


## Checks if a straight line can be traced from the Guard to a certain point.
## It returns true if the path to the point is free of walls.
## Note: it only detects sight_occluders collisions, not wall collisions, this
## is so water doesn't block sight.
func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()


## Patrol point index to global position
func _patrol_point_position(point_idx: int) -> Vector2:
	var local_point_position: Vector2 = patrol_path.curve.get_point_position(point_idx)
	return patrol_path.to_global(local_point_position)


func _amount_of_patrol_points() -> int:
	return patrol_path.curve.point_count


## Returns true if the end of the patrol path is the same point as the beginning
func _is_patrol_path_closed() -> bool:
	if not patrol_path:
		return false

	var curve: Curve2D = patrol_path.curve
	if curve.point_count < 3:
		return false

	var first_point_position: Vector2 = curve.get_point_position(0)
	var last_point_position: Vector2 = curve.get_point_position(curve.point_count - 1)

	return first_point_position.is_equal_approx(last_point_position)


## Resets the guard to its initial values and placement on screen so it starts
## patrolling again as if the level just started.
func _reset() -> void:
	previous_patrol_point_idx = -1
	current_patrol_point_idx = 0
	velocity = Vector2.ZERO
	if patrol_path:
		global_position = _patrol_point_position(0)


## When the scene is saved, resets the Guard's position to the beginning of
## the patrol path.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_reset()


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
		state = State.DETECTING


func _on_detection_area_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_player = null
	last_seen_position = body.global_position
	if state == State.DETECTING:
		guard_movement.stop_moving()
		state = State.INVESTIGATING
