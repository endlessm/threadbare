class_name PlayerController
extends Node

var axis: Vector2 = Vector2.ZERO
var running: bool = false
var interacting: bool = false


func _process(_delta: float) -> void:
	reset()
	
	if Pause.is_paused(Pause.System.PLAYER_INPUT):
		return

	axis = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	running = Input.is_action_pressed(&"running")
	interacting = Input.is_action_just_released(&"ui_accept")


func reset() -> void:
	axis = Vector2.ZERO
	running = false
	interacting = false
