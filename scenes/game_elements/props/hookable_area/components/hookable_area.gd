# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name HookableArea
extends Area2D
## @experimental
##
## Area to connect the grappling hook.
##
## An area to connect the grappling hook to the scene owner.
## While the final connection is a single [member anchor_point],
## the collision is checked against this area that should be big enough
## for player forgiveness.
## [br][br]
## This is a piece of the grappling hook mechanic.
## [br][br]
## When the grappling hook ray enters, it connects at the
## [member anchor_point].
## [br][br]
## If [member hook_control] is provided, this becomes a connection
## so the grappling hook can in turn aim from here.
## [br][br]
## If this is not a connection, it will be pulled automatically.
## When pulled, the owner of this area could be attracted to the player,
## or the player can be attracted to this node's owner (or something in between)
## depending on the value of [member weight] and the owner being a
## [CharacterBody2D].
## [br][br]
## [b]Note:[/b] This area is expected to be in the "hookable" collision layer.

const HOOKABLE_LAYER = 13

## Optional control to make this area a connection.
@export var hook_control: HookControl

## The exact point to attach the string.
@export var anchor_point: Marker2D

## When the grappling hook pulls and this area is hooked:[br]
## • 1: The player moves towards this.[br]
## • 0: This node's owner moves towards the player.[br]
## • Something in between: Both move depending on the value.[br][br]
## Not relevant if [member hook_control] is set.[br][br]
## If this node's owner is not a [CharacterBody2D], 1 is assumed.
@export var weight: float = 1.0


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not get_collision_layer_value(HOOKABLE_LAYER):
		warnings.append("Consider enabling collision with the hookable layer: %d." % HOOKABLE_LAYER)
	return warnings


func _set(property: StringName, _value: Variant) -> bool:
	if property == "collision_layer":
		update_configuration_warnings()
	return false
