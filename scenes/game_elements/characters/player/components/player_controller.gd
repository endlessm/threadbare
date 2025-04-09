# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node


func is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return not inputs_paused() and Input.is_action_pressed(action, exact_match)


func is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	return not inputs_paused() and Input.is_action_just_pressed(action, exact_match)


func is_action_just_released(action: StringName, exact_match: bool = false) -> bool:
	#Since inputs being paused is assumed to be like if the player suddenly
	#left the controller inactive, we don't check the pause for release
	return Input.is_action_just_released(action, exact_match)


func get_vector(
	negative_x: StringName,
	positive_x: StringName,
	negative_y: StringName,
	positive_y: StringName,
	deadzone: float = -1.0
) -> Vector2:
	return (
		Vector2.ZERO
		if inputs_paused()
		else Input.get_vector(negative_x, positive_x, negative_y, positive_y, deadzone)
	)


func inputs_paused() -> bool:
	return Pause.is_paused(Pause.System.PLAYER_INPUT)
