class_name HookableArea
extends Area2D
## Area to connect the grappling hook.
##
## It is an important piece of the grappling hook mechanic.[br][br]
##
## When the grappling hook ray enters, it connects at the
## [member hooking_point].[br][br]
##
## If [member hook_control] is provided, this becomes a connection
## so the grappling hook can in turn hook from here.[br][br]
##
## If this is not a connection, it could be pulled. For
## that the owner must be a [CharacterBody2D].[br][br]
##
## Note: This area is expected to be in the "hookable" collision layer.

## When this is hooked:
## - 1: The other side moves towards this.
## - 0: This moves towards the other side.
@export var weight: float = 1.0

## Whether this can be pulled.
## TODO: Change for weight == 1?
@export var is_pullable: bool = true

## Whether the player will pull automatically at the moment
## this is hooked. Only if [member pullable] is true.
@export var autopull: bool = true

## Add a hook control if this area is a connection.
## TODO: If this area has a hook control, then
## all the above is irrelevant / false
@export var hook_control: HookControl

## Its global position will be used to connect the string.
@export var hooking_point: Marker2D


## Return the hooking point global position.
func get_hooking_position() -> Vector2:
	return hooking_point.global_position
