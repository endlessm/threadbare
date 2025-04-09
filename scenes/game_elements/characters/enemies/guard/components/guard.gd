# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Guard extends CharacterBody2D
## Enemy type that patrols along a path and raises an alert if the player is detected.

## Emitted when the player is detected.
signal player_detected(player: Node2D)

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

const LOOK_AT_TURN_SPEED: float = 10.0

@export_category("Patrol")
@warning_ignore("unused_private_class_variable")
@export_tool_button("Edit Patrol Path") var _edit_patrol_path: Callable = edit_patrol_path
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
	set = _change_state

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
## Area that represents the sight of the guard. If a player is in this area
## and there are no walls in between detected by [member sight_ray_cast], it
## means the player is in sight.
@onready var detection_area: Area2D = %DetectionArea
## Progress bar that indicates how aware the guard is of the player, if it
## is completely filled, [signal player_detected] is triggered.
@onready var player_awareness: TextureProgressBar = %PlayerAwareness
## Smaller detection area that only detectes when the player is really
## close to the guard. If it detects a player, [signal player_detected] is
## triggered.
@onready var instant_detection_area: Area2D = %InstantDetectionArea
## RayCast used to detect if the sight to a position is blocked.
@onready var sight_ray_cast: RayCast2D = %SightRayCast
## Control to hold debug info that can be toggled on or off.
@onready var debug_info: Label = %DebugInfo
## Handles the velocity and movement of the guard.
@onready var guard_movement: GuardMovement = %GuardMovement


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Player awareness is configured and started empty.
		if player_awareness:
			player_awareness.max_value = time_to_detect_player
			player_awareness.value = 0.0

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

	_update_direction(delta)

	var player_in_sight: Node2D = _player_in_sight()
	_detect_player(player_in_sight)
	_update_player_awareness(player_in_sight, delta)

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
		State.DETECTING:
			guard_movement.stop_moving()
			if not _player_in_sight():
				_change_state(State.INVESTIGATING)
		State.RETURNING:
			if not breadcrumbs.is_empty():
				var target_position: Vector2 = breadcrumbs.back()
				guard_movement.set_destination(target_position)
			else:
				_change_state(State.PATROLLING)
		State.ALERTED:
			guard_movement.stop_moving()


## Updates where the Guard is looking at.
func _update_direction(delta: float) -> void:
	if velocity.is_zero_approx():
		return

	var target_angle: float = velocity.angle()
	detection_area.rotation = rotate_toward(
		detection_area.rotation, target_angle, delta * LOOK_AT_TURN_SPEED
	)

	if sprite and not is_zero_approx(velocity.x):
		sprite.flip_h = velocity.x < 0


## Tries to detect the player in sight and changes state accordingly if player
## is spotted. If player_in_sight is null it means it isn't in sight.
func _detect_player(player_in_sight: Node2D) -> void:
	if not player_in_sight:
		return

	last_seen_position = player_in_sight.global_position

	if (
		instant_detection_area.has_overlapping_bodies()
		or player_awareness.ratio >= 1.0
		or player_instantly_detected_on_sight
	):
		_change_state(State.ALERTED)
	else:
		_change_state(State.DETECTING)


## Changes how PlayerAwareness looks to reflect how close is the player to
## being detected
func _update_player_awareness(player_in_sight: Node2D, delta: float) -> void:
	if State.ALERTED == state:
		player_awareness.ratio = 1.0
		player_awareness.tint_progress = Color.RED
	else:
		player_awareness.value = move_toward(
			player_awareness.value, player_awareness.max_value if player_in_sight else 0.0, delta
		)
	player_awareness.visible = player_awareness.ratio > 0.0
	player_awareness.modulate.a = clamp(player_awareness.ratio, 0.5, 1.0)


func _update_animation() -> void:
	if state == State.ALERTED and sprite.animation == &"alerted":
		return

	if velocity.is_zero_approx():
		sprite.play(&"idle")
	else:
		sprite.play(&"walk")


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


## What happens when a certain state is
func _on_enter_state(new_state: State) -> void:
	match new_state:
		State.ALERTED:
			player_detected.emit(_player_in_sight())
			await get_tree().create_timer(0.4).timeout
			sprite.play(&"alerted")
		State.INVESTIGATING:
			guard_movement.start_moving_now()
			breadcrumbs.push_back(global_position)


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
			_change_state(State.RETURNING)


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
			_change_state(State.RETURNING)
		State.RETURNING:
			if not breadcrumbs.is_empty():
				breadcrumbs.pop_back()


func _change_state(next_state: State) -> void:
	if next_state == state:
		return

	state = next_state
	_on_enter_state(state)


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


## Returns a Player if it is in sight and there isn't any wall blocking it.
## Otherwise, it returns null.
func _player_in_sight() -> Node2D:
	if instant_detection_area.has_overlapping_bodies():
		return instant_detection_area.get_overlapping_bodies().front()

	if not detection_area.has_overlapping_bodies():
		return null

	var player: Node2D = detection_area.get_overlapping_bodies().front()

	if _is_sight_to_point_blocked(player.global_position):
		return null

	return player


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


## Function used for a tool button that either selects the current patrol_path
## in the editor, or creates a new one
func edit_patrol_path() -> void:
	if not Engine.is_editor_hint():
		return

	# Cannot directly reference [class EditorInterface] in code that isn't
	# part of a script that runs only in the editor (like plugins).
	# This function should only be called in the editor, but having a direct
	# reference to the [class EditorInterface] causes errors on runtime builds.
	var editor_interface: Object = Engine.get_singleton("EditorInterface")

	if patrol_path:
		editor_interface.edit_node.call_deferred(patrol_path)
	else:
		var new_patrol_path: Path2D = Path2D.new()
		patrol_path = new_patrol_path
		get_parent().add_child(patrol_path)
		patrol_path.owner = owner
		patrol_path.global_position = global_position
		patrol_path.curve = Curve2D.new()
		patrol_path.name = "%s-PatrolPath" % name
		editor_interface.edit_node.call_deferred(patrol_path)
