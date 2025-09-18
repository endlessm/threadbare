extends Node2D

## The controlled camera.
@export var camera: Camera2D:
	set = _set_camera

## The target.
@export var target: Node2D


func _enter_tree() -> void:
	if not camera and get_parent() is Camera2D:
		camera = get_parent()


func _set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not camera:
		warnings.append("Camera must be set.")
	return warnings


func _ready() -> void:
	if not camera.enabled or not camera.is_current():
		set_process(false)
		return


func _process(_delta: float) -> void:
	if not target:
		return
	camera.global_position = target.global_position
