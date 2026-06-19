# Script used to move the bacgroun while dialogue runs

extends Control

var speed : float = 0.0
@warning_ignore("narrowing_conversion")
var y_length : int = 0.0
@warning_ignore("narrowing_conversion")
var x_length : int = 0.0

## Camera
@export var camera : Camera2D

## Background
@export var background : TextureRect

## Duration in seconds of moving background	
@export var duration : float = 10.0



func _ready() -> void:
	y_length = (int)(background.size.y * background.scale.y)
	x_length = (int)(background.size.x * background.scale.x)
	# limiting the camera
	camera.limit_bottom = y_length
	camera.limit_right = x_length
	speed = y_length / duration
	

## Sets the background scale depending on viewport
func set_scale_for_background() -> void:
	var scale_x = get_viewport_rect().size.x / background.size.x
	var scale_y = get_viewport_rect().size.y / background.size.y
	background.scale = Vector2(scale_x, scale_y)
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera.move_local_y(speed * delta)
