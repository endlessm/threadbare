class_name HookableArea
extends Area2D

## 1: player moves towards this
## 0: owner moves towards player
@export var weight: float = 1.0

@onready var marker_2d: Marker2D = $Marker2D


func get_hooking_point() -> Vector2:
	return marker_2d.global_position
