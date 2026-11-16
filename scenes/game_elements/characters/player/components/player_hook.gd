# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerHook
extends Node2D
## @experimental
##
## Grappling hook tool.
##
## The player can use it to hook things in the world: collect items,
## reach otherwise unreachable places, solve puzzles.
## [br][br]
## This is a piece of the grappling hook mechanic.
## [br][br]
## It should be in group [b]hook_listener[/b] so functions [method hooked],
## [method hit_wall] and [method hit_air] are called.

## Emitted when the string is thrown from the primary control.
signal string_thrown

## The character using the grapping hook tool.
## [br][br]
## [b]Note:[/b] If the parent node is a CharacterBody2D and character isn't set,
## the parent node will be automatically assigned to this variable.
@export var character: CharacterBody2D:
	set = _set_character

## How far can the initial throw reach.
@export_range(0.0, 500.0, 1.0, "or_greater") var string_throw_length: float = 200.0:
	set(new_val):
		string_throw_length = new_val
		hook_control.string_length = string_throw_length

## The velocity of both the character and the thing being pulled, while pulling.
@export_range(0.0, 5000.0, 1.0, "or_greater", "or_less") var pull_velocity: float = 1000.0

## The speed below which the character or the thing being pulled are considered stuck.
@export_range(0, 100000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 100.0

## Maximum length of the first section of the string.
## [br][br]
## If the string is connected and the player walks in the opposite direction,
## going further this distance cancels all the connections, removing the string.
## Must be bigger than [member string_throw_length].
@export_range(0.0, 500.0, 1.0, "or_greater") var string_max_length: float = 250.0

## The string minimum length while pulling.
## [br][br]
## When this length is reached, The pull will be cancelled and the string will be removed.
@export_range(0.0, 500.0, 1.0, "or_greater") var string_stop_pulling_length: float = 10.0

## The string minimum length when thrown to the air and returning.
## [br][br]
## While returning, the string will be removed when this length is reached.
@export_range(0.0, 500.0, 1.0, "or_greater") var string_air_min_length: float = 10.0

## Repeatable texture to dress the line. It should wrap horizontally.
@export var hook_string_texture: Texture2D = preload("uid://q3c2qavtccvu")

## All the areas that have been hooked and through which anchor points
## the [member hook_string] passes.
## [br][br]
## If this array has more than one area, then all except the last one must
## be connections.
## [br][br]
## If the last area is not a connection, the player pulls it.
## While pulling, the area controlled entity and the player get closer and closer,
## passing through all the connections in between, until the hook string
## is consumed.
var areas_hooked: Array[HookableArea]

## True if a pull is happening.
var pulling: bool = false

## The hook string.
## [br][br]
## This line starts at the player and goes through all [member areas_hooked].
## The last point can also be in the air.
var hook_string: Line2D

## The primary control.
## [br][br]
## It is set to aiming when there is no [member hook_string].
@onready var hook_control: HookControl = $HookControl

## Marker which position is set to the ending of the hook.
## [br][br]
## This can be used to pan or zoom the camera to frame the ending of the grappling hook.
@onready var hook_ending: Marker2D = $HookEnding


func _enter_tree() -> void:
	if not character and get_parent() is CharacterBody2D:
		character = get_parent()


func _set_character(new_character: CharacterBody2D) -> void:
	character = new_character
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not character:
		warnings.append("Character must be set.")
	return warnings


func _ready() -> void:
	hook_control.string_length = string_throw_length


func _new_hook_string() -> Line2D:
	var new_hook_string := Line2D.new()
	new_hook_string.width = 16
	new_hook_string.texture = hook_string_texture
	new_hook_string.texture_mode = Line2D.LINE_TEXTURE_TILE
	new_hook_string.joint_mode = Line2D.LINE_JOINT_ROUND
	new_hook_string.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	new_hook_string.add_point(global_position)
	character.add_sibling(new_hook_string)
	new_hook_string.owner = character.owner
	string_thrown.emit()
	return new_hook_string


## Called when the area was hooked.
## [br][br]
## Part of group hook_listener.
func hooked(_new_hooked_to: HookableArea, is_loop: bool) -> void:
	var p: Vector2 = _new_hooked_to.get_anchor_position()
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(p, 0)
	hook_ending.global_position = p
	areas_hooked.append(_new_hooked_to)
	if not _new_hooked_to.hook_control:
		pull_string()
	if is_loop:
		# Play a blink animation and then remove the string:
		var tween: Tween = create_tween()
		tween.tween_property(hook_string, "modulate:a", 0.0, 0.1).set_trans(
			Tween.TransitionType.TRANS_LINEAR
		)
		tween.tween_property(hook_string, "modulate:a", 1.0, 0.1).set_trans(
			Tween.TransitionType.TRANS_LINEAR
		)
		tween.set_loops(8)
		tween.play()
		await tween.finished
		remove_string()


## Called when a throw has hit a wall.
## [br][br]
## Part of group hook_listener.
func hit_wall(wall_point: Vector2) -> void:
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(wall_point, 0)
	areas_hooked.append(null)


## Called when a throw has hit the air.
## [br][br]
## Part of group hook_listener.
func hit_air(air_point: Vector2) -> void:
	if not hook_string:
		hook_string = _new_hook_string()
	hook_string.add_point(air_point, 0)
	areas_hooked.append(null)


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
			area.hook_control.release()
			area.hook_control.state = HookControl.State.DISABLED
	areas_hooked.clear()

	# Wait for the string to be freed before reenabling aiming:
	if is_instance_valid(hook_string):
		await hook_string.tree_exited

	# Reenable aiming so a new string can be thrown:
	hook_control.release()
	hook_control.state = HookControl.State.AIMING

	hook_ending.global_position = global_position


## Start pulling.
## [br][br]
## While pulling, the player is allowed to go through non-walkable floor.
func pull_string() -> void:
	pulling = true
	character.set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, false)


## Stop pulling and remove the [member hook_string].
## [br][br]
## After pulling, the player is back to normal and not able to go through
## non-walkable floor.
func stop_pulling() -> void:
	character.set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, true)
	pulling = false
	remove_string()


## True if this hook's control is throwing or the hook control of the last area hooked is aiming.
## [br][br]
## Used to slow down the character movement for more precise control.
func is_throwing_or_aiming() -> bool:
	var ending_area := get_ending_area()
	return (
		hook_control.pressing_throw_action
		or (
			ending_area
			and ending_area.hook_control
			and ending_area.hook_control.state == HookControl.State.AIMING
		)
	)


## Helper function to return the last area hooked, or
## null if nothing was hooked.
func get_ending_area() -> HookableArea:
	if areas_hooked.is_empty():
		return null
	return areas_hooked[-1]


func _process(delta: float) -> void:
	if not is_instance_valid(hook_string):
		return
	if pulling:
		# When pulling, update the player position and / or the target position.
		_process_pulling(delta)
	# Update the points in the grappling hook string.
	_process_hook_string(delta)


func _process_hook_string(delta: float) -> void:
	# Only one point in the Line2D, so not a line.
	# This shouldn't ever happen.
	if hook_string.get_point_count() < 2:
		push_error("Only one point in hook_string.")
		return

	# Update the string points to match the position of the things hooked.
	# TODO: Only updates the endings. Connections are assumed static for now.

	# Move last point to the player position.
	hook_string.points[-1] = character.position + position

	var ending_area := get_ending_area()
	if ending_area:
		# Move first point to the hooked position.
		hook_string.points[0] = ending_area.get_anchor_position()

	else:
		# Not hooked, so a throw that hit air or wall.
		# Progressively shorten the line.
		hook_string.points[0] = hook_string.points[0].lerp(hook_string.points[1], 10.0 * delta)
		# Remove the string when the line is short enough.
		if (
			(hook_string.points[1] - hook_string.points[0]).length_squared()
			< string_air_min_length * string_air_min_length
		):
			remove_string()

	if not pulling:
		var v: Vector2 = hook_string.points[-1] - hook_string.points[-2]
		if v.length_squared() > string_max_length * string_max_length:
			remove_string()


func _process_pulling(_delta: float) -> void:
	# Return if the thing that was being pulled was removed:
	var ending_area := get_ending_area()
	if not is_instance_valid(ending_area):
		stop_pulling()
		return

	var target := ending_area.controlled_entity
	var weight := ending_area.weight if target is CharacterBody2D else 1.0

	# Vector from player to first point:
	var player_distance: Vector2 = hook_string.points[-2] - hook_string.points[-1]

	# Vector from target to previous point:
	var target_distance: Vector2 = hook_string.points[1] - hook_string.points[0]

	# The player moves if the target weight isn't zero:
	if weight != 0:
		if (
			player_distance.length_squared()
			< string_stop_pulling_length * string_stop_pulling_length
		):
			if hook_string.get_point_count() > 2:
				# TODO upstream: Line2D.remove_point() doesn't accept negative index:
				hook_string.remove_point(hook_string.get_point_count() - 1)
				return
			stop_pulling()
			return

	# The target moves if its weight isn't one:
	if weight != 1:
		if (
			target_distance.length_squared()
			< string_stop_pulling_length * string_stop_pulling_length
		):
			if hook_string.get_point_count() > 2:
				hook_string.remove_point(0)
				return
			stop_pulling()
			return

	character.velocity = player_distance.normalized() * pull_velocity * weight
	var player_collided := character.move_and_slide()

	if player_collided:
		if character.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
			stop_pulling()

	if target is CharacterBody2D:
		target.velocity = target_distance.normalized() * pull_velocity * (1 - weight)
		var target_collided := (target as CharacterBody2D).move_and_slide()
		if target_collided:
			if target.get_real_velocity().length_squared() <= stuck_speed * stuck_speed:
				stop_pulling()
