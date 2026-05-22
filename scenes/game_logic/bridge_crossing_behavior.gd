# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BridgeCrossingBehavior
extends Area2D
## Adjusts character collision layers when they walk across bridges
##
## Bridges cross non-walkable floor layers, like water or void, as well as
## cliff edges, which also have collisions to stop the character walking off the
## edge. are walls. This component detects when the character is walking across
## a bridge & adjusts the collisions on the character. Give it a collision
## shape that has the same centre as [member character]'s collision shape but
## is a bit smaller.

## The character controlled by this component. Typically this is this
## node's parent, in which case this will be configured automatically.
@export var character: CharacterBody2D:
	set = _set_character


func _set_character(new_value: CharacterBody2D) -> void:
	character = new_value
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not character:
		warnings.append("No character set.")
	return warnings


func _enter_tree() -> void:
	if not character and get_parent() is CharacterBody2D:
		character = get_parent()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(Enums.CollisionLayers.BRIDGE, true)

	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_bridge_entered)
	body_exited.connect(_on_bridge_exited)


func _on_bridge_entered(_body: Node2D) -> void:
	_set_on_bridge(true)


func _on_bridge_exited(_body: Node2D) -> void:
	_set_on_bridge(false)


func _set_on_bridge(on_bridge: bool) -> void:
	character.set_collision_mask_value(Enums.CollisionLayers.NON_WALKABLE_FLOOR, not on_bridge)
	character.set_collision_mask_value(Enums.CollisionLayers.WALLS, not on_bridge)
	character.set_collision_mask_value(Enums.CollisionLayers.BRIDGE_EDGE, on_bridge)
