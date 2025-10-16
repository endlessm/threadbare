# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HookControl
extends Node2D
## @experimental
##
## Control for the grappling hook.
##
## Handles the input to control the aiming and throwing.
## This is a piece of the grappling hook mechanic.
## [br][br]
## The [b]throw[/b] action is used for throwing.
## [br][br]
## The [b]aim_up, aim_down, aim_left and aim_right[/b] actions are used for aiming.
## Additionally, the mouse movement can also be used for aiming,
## but the mouse not considered the primary input.
## [br][br]
## Aiming is effectively rotating the [member ray_cast_2d].
## [br][br]
## Visually it displays the [member sprite_2d] texture pointing in the
## ray's direction.
## The arrow is semitransparent when the ray doesn't hit anything.
## [br][br]
## The [b]hook_listener[/b] group is notified by this control when throwing
## about the outcome of the throw: if an area was hooked, if it hit a wall
## or if it hit the air (hit nothing).
## The [b]hook_listener[/b] group is also notified when the control releases an
## area previously hooked.

## The control state.
enum State {
	## The control does not respond to user input and doesn't update.
	DISABLED,
	## The control responds to user input and updates.
	AIMING,
	## The control is temporarily paused from aiming. For example, while throwing.
	AIMING_PAUSED,
}

## How far a throw from this control can reach.
## This is the length of the [member ray_cast_2d].
@export_range(0.0, 500.0, 1.0, "or_greater") var string_length: float = 200.0:
	set(new_value):
		string_length = new_value
		ray_cast_2d.target_position = Vector2(string_length, 0)

## The current state. Starts disabled.
@export var state: State = State.DISABLED:
	set = _set_state

## The initial angle to throw the hook.
## This will be used only until user input is pressed.
@export_range(0, 360, 1, "radians_as_degrees") var initial_hook_angle: float

## The area to which this control is attached, if any.
@export var hook_area: HookableArea

## Exclude these areas from connecting.
## This is used for excluding the immediate previous area, preventing a string
## that goes from A to B, and then immediately from B to A.
@export var exclude_areas: Array[HookableArea]

## The are currently hooked by this control.
var hooked_to: HookableArea

## True if the throw action is currently pressed.
var pressing_throw_action: bool = false

## True if during a long press of the throw action, a throw went to the air or wall.
var throw_failed_while_pressing: bool = false

# This boolean is needed because we can't distinguish between a _hook_angle that is
# initially 0.0 from a _hook_angle set to 0.0 by user input.
var _hook_angle_set: bool = false

var _hook_angle: float

## The visual representation of the [member ray_cast_2d] direction.
## It also indicates if the ray is hitting a [HookableArea] by displaying
## the sprite solid, or semitransparent if not.
@onready var sprite_2d: Sprite2D = %Sprite2D

## The ray cast to handle collisions with hookable areas.
@onready var ray_cast_2d: RayCast2D = %RayCast2D

## Timer to let a directional pad continue aiming in
## diagonal directions when releasing the input actions.
@onready var d_pad_timer: Timer = %DPadTimer


func _unhandled_input(_event: InputEvent) -> void:
	if _event is InputEventMouseMotion:
		var axis := get_global_mouse_position() - global_position
		if not axis.is_zero_approx():
			_hook_angle = axis.angle()
			_hook_angle_set = true
		return

	# When aiming with keyboard, do not change the hook angle immediately if one of these actions
	# was released. This makes it possible to aim in diagonal directions.
	# Otherwise, if for example left and down are pressed to aim in diagonal and both are released,
	# there is always one that is released first so the aim direction ends up being either left or
	# down, not left AND down.
	if (
		_event is InputEventKey
		and (
			_event.is_action_released(&"aim_left")
			or _event.is_action_released(&"aim_right")
			or _event.is_action_released(&"aim_up")
			or _event.is_action_released(&"aim_down")
		)
	):
		d_pad_timer.start()
		return

	_update_hook_angle()

	if Input.is_action_just_pressed(&"throw"):
		pressing_throw_action = true
		return

	if Input.is_action_just_released(&"throw"):
		pressing_throw_action = false
		throw_failed_while_pressing = false
		return


func _update_hook_angle() -> void:
	var axis: Vector2
	axis = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if not axis.is_zero_approx():
		if pressing_throw_action:
			_hook_angle = rotate_toward(_hook_angle, axis.angle(), 0.05)
			_hook_angle_set = true
		else:
			_hook_angle = axis.angle()
			_hook_angle_set = true


func _get_hook_angle() -> float:
	return _hook_angle if _hook_angle_set else initial_hook_angle


func _throw() -> void:
	if ray_cast_2d.is_colliding():
		if _can_connect():
			hooked_to = ray_cast_2d.get_collider() as HookableArea
			var is_loop := false
			if hooked_to.hook_control:
				is_loop = is_instance_valid(hooked_to.hook_control.hooked_to)
				if not is_loop:
					hooked_to.hook_control.state = State.AIMING
					hooked_to.hook_control.initial_hook_angle = _get_hook_angle()
					if hook_area:
						hooked_to.hook_control.exclude_areas.append(hook_area)
				state = State.DISABLED
			get_tree().call_group(&"hook_listener", &"hooked", hooked_to, is_loop)
		else:
			release()
			var wall_point := ray_cast_2d.get_collision_point()
			get_tree().call_group(&"hook_listener", &"hit_wall", wall_point)
			throw_failed_while_pressing = true
			state = State.AIMING_PAUSED
	else:
		release()
		var air_point := global_position + Vector2(string_length, 0).rotated(_get_hook_angle())
		get_tree().call_group(&"hook_listener", &"hit_air", air_point)
		throw_failed_while_pressing = true
		state = State.AIMING_PAUSED


## If an area is hooked, disconnect it.
func release() -> void:
	if hooked_to:
		if hooked_to.hook_control:
			hooked_to.hook_control.exclude_areas.erase(hook_area)
		get_tree().call_group(&"hook_listener", &"released", hooked_to)
		hooked_to = null


func _can_connect() -> bool:
	if not ray_cast_2d.is_colliding():
		return false
	var area := ray_cast_2d.get_collider() as HookableArea
	if not area:
		return false
	return area not in exclude_areas


func _set_state(new_state: State) -> void:
	state = new_state
	if not ready:
		return
	if state == State.DISABLED:
		rotation = 0
		pressing_throw_action = false
		throw_failed_while_pressing = false
	if sprite_2d:
		sprite_2d.visible = state != State.DISABLED
	if ray_cast_2d:
		ray_cast_2d.enabled = state != State.DISABLED
	set_process_unhandled_input(state != State.DISABLED)


func _ready() -> void:
	_set_state(state)


func _process(_delta: float) -> void:
	if state == State.DISABLED:
		return
	rotation = _get_hook_angle()
	sprite_2d.modulate = Color.WHITE if _can_connect() else Color(Color.WHITE, 0.5)
	if hooked_to:
		# Currently the control can be hooked to a single area.
		return
	if state != State.AIMING_PAUSED and pressing_throw_action and not throw_failed_while_pressing:
		_throw()


func _on_d_pad_timer_timeout() -> void:
	_update_hook_angle()
