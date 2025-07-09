class_name HookableArea
extends Area2D

## 1: player moves towards this
## 0: owner moves towards player
@export var weight: float = 1.0

## Whether the player can pull this.
@export var is_pullable: bool = true

## Whether the player will pull automatically at the moment
## this is hooked. Only if [member pullable] is true.
@export var autopull: bool = true

## Add a hook control if this area is a connection.
## TODO: If this area has a hook control, then
## all the above is irrelevant / false
@export var hook_control: HookControl

## The position to connect the string.
@onready var marker_2d: Marker2D = $Marker2D


func get_hooking_point() -> Vector2:
	return marker_2d.global_position
