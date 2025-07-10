class_name HookableArea
extends Area2D

@onready var marker_2d: Marker2D = $Marker2D


func get_hooking_point() -> Vector2:
	return marker_2d.global_position
