# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerHook
extends Node2D

signal string_thrown

const NON_WALKABLE_FLOOR_LAYER: int = 10

@export_range(0.0, 500.0, 1.0, "or_greater") var string_throw_length: float = 200.0:
	set(new_val):
		string_throw_length = new_val
		hook_control.string_length = string_throw_length

@export_range(0, 100000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 100.0

@export_range(0.0, 500.0, 1.0, "or_greater") var string_max_length: float = 300.0
@export_range(0.0, 500.0, 1.0, "or_greater") var string_min_length: float = 10.0
@export_range(0.0, 500.0, 1.0, "or_greater") var string_stop_pulling_length: float = 10.0
@export var full_stop_after_pull: bool = false
@export_range(0.0, 5000.0, 1.0, "or_greater", "or_less") var pull_velocity: float = 1000.0
@export_range(0.0, 1.0, 0.1) var bounce_amount_when_stuck: float = 0.0
@export var hook_string_texture: Texture2D = preload("res://scenes/hook-string.png")

var debug_no_air_throw: bool = false
var debug_hit_from_inside: bool = false:
	set(new_value):
		debug_hit_from_inside = new_value
		ray_cast_2d.hit_from_inside = debug_hit_from_inside

## All the areas that have been hooked and through which anchor points
## the [member hook_string] passes.[br][br]
##
## If this array has more than one area, then all except the last one must
## be connections.[br][br]
##
## If the last area is not a connection, the player can pull it.
## When pulling, the area owner and the player get closer and closer,
## passing through all the connections in between, until the hook string
## is consumed.
var areas_hooked: Array[HookableArea]

## True if a pull is happening.
var pulling: bool = false

## The hook string.
##
## This line starts at the player and goes through all [member areas_hooked],
## and the last point can also be in the air.
var hook_string: Line2D

@onready var player: Player = self.owner as Player
@onready var ray_cast_2d: RayCast2D = $HookControl/RayCast2D
@onready var hook_control: HookControl = $HookControl


func _ready() -> void:
	if GameState.got_longer_hook:
		string_throw_length = 400.0
		string_max_length = 600.0
	hook_control.string_length = string_throw_length
	if debug_hit_from_inside:
		ray_cast_2d.hit_from_inside = true


func _new_hook_string() -> Line2D:
	var new_hook_string := Line2D.new()
	new_hook_string.width = 16
	new_hook_string.texture = hook_string_texture
	new_hook_string.texture_mode = Line2D.LINE_TEXTURE_TILE
	new_hook_string.joint_mode = Line2D.LINE_JOINT_ROUND
	new_hook_string.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	new_hook_string.add_point(global_position)
	player.add_sibling(new_hook_string)
	new_hook_string.owner = player.owner
	string_thrown.emit()
	return new_hook_string


func hit_target(_new_hooked_to: HookableArea) -> void:
	var p: Vector2 = _new_hooked_to.anchor_point.global_position
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(p, 0)
	areas_hooked.append(_new_hooked_to)
	if _new_hooked_to.autopull:
		pull_string()


func hit_wall(wall_point: Vector2) -> void:
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(wall_point, 0)


func hit_air(air_point: Vector2) -> void:
	if debug_no_air_throw:
		return
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(air_point, 0)


## Remove the [member hook_string].
func remove_string() -> void:
	if pulling:
		return

	if hook_string:
		hook_string.queue_free()

	for area: HookableArea in areas_hooked:
		# The area may be freed. For example, when the player
		# collects a button.
		if not is_instance_valid(area):
			continue
		if area.hook_control:
			area.hook_control.hooked_to = null
			area.hook_control.state = HookControl.State.DISABLED
	areas_hooked.clear()

	# Wait for the string to be freed before reenabling aiming:
	if is_instance_valid(hook_string):
		await hook_string.tree_exited

	# Reenable aiming so a new string can be thrown:
	hook_control.hooked_to = null
	hook_control.state = HookControl.State.AIMING


## Start pulling.[br][br]
##
## While pulling, the player is allowed to go through non-walkable floor.
func pull_string() -> void:
	pulling = true
	player.set_collision_mask_value(NON_WALKABLE_FLOOR_LAYER, false)


## Stop pulling and remove the [member hook_string].[br][br]
##
## After pulling, the player is back to normal and not able to go through
## non-walkable floor.
func stop_pulling() -> void:
	player.set_collision_mask_value(NON_WALKABLE_FLOOR_LAYER, true)
	pulling = false
	remove_string()


## Helper function to return the last area hooked, or
## null if nothing was hooked.
func get_ending_area() -> HookableArea:
	if areas_hooked.is_empty():
		return null
	return areas_hooked[-1]


func _unhandled_input(_event: InputEvent) -> void:
	# TODO: and not pulling:
	if Input.is_action_just_pressed(&"repel") and hook_string:
		remove_string()
		return

	if Input.is_action_just_released(&"throw"):
		var ending_area := get_ending_area()
		if ending_area and not ending_area.hook_control:
			pull_string()
		return


func _process(delta: float) -> void:
	# TODO: if not is_instance_valid(hook_string) return

	# Only one point in the Line2D, so not a line.
	# This shouldn't ever happen.
	if is_instance_valid(hook_string) and hook_string.get_point_count() < 2:
		push_error("Only one point in hook_string.")
		return

	if is_instance_valid(hook_string):
		# Move last point to the player position.
		hook_string.points[-1] = player.position + position
		var ending_area := get_ending_area()
		if ending_area:
			# Move first point to the hooked position.
			hook_string.points[0] = ending_area.anchor_point.global_position
		else:
			# Not hooked, so a throw that hit air or wall.
			# Progressively shorten the line.
			hook_string.points[-2] = hook_string.points[-2].lerp(
				hook_string.points[-1], 10.0 * delta
			)
			# Remove the string when the line is short enough.
			if (
				(hook_string.points[-2] - hook_string.points[-1]).length_squared()
				< string_min_length * string_min_length
			):
				remove_string()

	if not pulling:
		if is_instance_valid(hook_string):
			var v: Vector2 = hook_string.points[0] - hook_string.points[-1]
			if v.length_squared() > string_max_length * string_max_length:
				remove_string()

	else:
		_process_pulling(delta)


func _process_pulling(_delta: float) -> void:
	# The thing that was being pulled was freed, or the string was freed:
	var ending_area := get_ending_area()
	if not is_instance_valid(ending_area) or not is_instance_valid(hook_string):
		stop_pulling()
		return
	var target := ending_area.owner
	var weight := ending_area.weight if target is CharacterBody2D else 1.0
	# vector from player to first point
	var player_distance: Vector2 = hook_string.points[-2] - hook_string.points[-1]

	# vector from target to previous point
	var target_distance: Vector2 = hook_string.points[1] - hook_string.points[0]

	# player moves if target weight isn't zero:
	if weight != 0:
		if (
			player_distance.length_squared()
			< string_stop_pulling_length * string_stop_pulling_length
		):
			if hook_string.get_point_count() > 2:
				# TODO upstream: Line2D.remove_point() doesn't accept negative index:
				hook_string.remove_point(hook_string.get_point_count() - 1)
				return
			if full_stop_after_pull:
				player.velocity = Vector2.ZERO
			stop_pulling()
			return

	# target moves if it's weight isn't one:
	if weight != 1:
		if (
			target_distance.length_squared()
			< string_stop_pulling_length * string_stop_pulling_length
		):
			if hook_string.get_point_count() > 2:
				hook_string.remove_point(0)
				return
			if full_stop_after_pull:
				target.velocity = Vector2.ZERO
			stop_pulling()
			return

	player.velocity = player_distance.normalized() * pull_velocity * weight
	var player_collided := player.move_and_slide()

	if player_collided:
		if player.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
			player.velocity *= -1 * bounce_amount_when_stuck
			stop_pulling()

	if target is CharacterBody2D:
		target.velocity = target_distance.normalized() * pull_velocity * (1 - weight)
		var target_collided := (target as CharacterBody2D).move_and_slide()
		if target_collided:
			if target.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
				target.velocity *= -1 * bounce_amount_when_stuck
				stop_pulling()
