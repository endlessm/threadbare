# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CharacterSpeeds
extends Resource
## @experimental
##
## Character movement speed parameters
##
## This resource holds speed parameters for character behaviors which enable walking or running,
## such as [InputWalkBehavior] and [FollowWalkBehavior]. Not all parameters are used by all
## behaviors.

## The character walking speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The character running speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var run_speed: float = 500.0

## How fast does the player transition from walking/running to stopped.
## A low value will make the character look as slipping on ice.
## A high value will stop the character immediately.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var stopping_step: float = 1500.0

## How fast does the player transition from stopped to walking/running.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var moving_step: float = 4000.0

## The speed below which the character is considered stuck.
## [br][br]
## What happens when the character is stuck depends on the behavior in use:
## it may emit a signal, or cause the character to change direction.
## [br][br]
## If this is less than [member walk_speed], the character may slide on walls
## when moving faster than this speed but below [member walk_speed].
## If this is close to or less than zero, the character may never be considered
## stuck.
@export_range(0, 1000, 10, "or_greater", "suffix:m/s") var stuck_speed: float = 300.0


## Check if the character's real velocity is below [member stuck_speed].
func is_stuck(character: CharacterBody2D) -> bool:
	return character.get_real_velocity().length_squared() < stuck_speed * stuck_speed
