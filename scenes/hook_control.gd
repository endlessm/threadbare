# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HookControl
extends Node2D

# signal connected

enum State {
	## Can be turned to aiming. So not like process mode disabled.
	DISABLED,
	## Aiming.
	AIMING,
	## Is aiming but can't throw for now.
	AIMING_PAUSED,
}

@export_range(0.0, 500.0, 1.0, "or_greater") var string_length: float = 200.0:
	set(new_value):
		string_length = new_value
		ray_cast_2d.target_position = Vector2(string_length, 0)

@export var state: State = State.DISABLED:
	set = _set_state

var connected_to: HookableArea
var pressing_throw_action = false
var _hook_angle: float

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var ray_cast_2d: RayCast2D = %RayCast2D


func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2

	if _event is InputEventMouseMotion:
		axis = get_global_mouse_position() - global_position
		if not axis.is_zero_approx():
			_hook_angle = axis.angle()
		return

	axis = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if not axis.is_zero_approx():
		if pressing_throw_action:
			_hook_angle = lerp_angle(_hook_angle, axis.angle(), 0.1)
		else:
			_hook_angle = axis.angle()

	if Input.is_action_just_pressed(&"throw"):
		pressing_throw_action = true
		return

	if Input.is_action_just_released(&"throw"):
		pressing_throw_action = false
		return


func _throw() -> void:
	if ray_cast_2d.is_colliding():
		if ray_cast_2d.get_collider() is HookableArea:
			connected_to = ray_cast_2d.get_collider() as HookableArea
			if connected_to.hook_control:
				connected_to.hook_control.state = State.AIMING
				state = State.DISABLED
			# ray_cast_2d.target_position = connected_to.get_hooking_point() - global_position
			get_tree().call_group(&"hook_listener", &"hit_target", connected_to)
		else:
			var wall_point := ray_cast_2d.get_collision_point()
			get_tree().call_group(&"hook_listener", &"hit_wall", wall_point)
			state = State.AIMING_PAUSED
	else:
		var air_point := global_position + Vector2(string_length, 0).rotated(_hook_angle)
		get_tree().call_group(&"hook_listener", &"hit_air", air_point)
		state = State.AIMING_PAUSED


func _can_connect() -> bool:
	return ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() is HookableArea


func _set_state(new_state: State) -> void:
	state = new_state
	if not ready:
		return
	if state == State.DISABLED:
		rotation = 0
		pressing_throw_action = false
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
	rotation = _hook_angle
	sprite_2d.modulate = Color.WHITE if _can_connect() else Color(Color.WHITE, 0.5)
	if connected_to:
		return
	if state != State.AIMING_PAUSED and pressing_throw_action:
		_throw()
