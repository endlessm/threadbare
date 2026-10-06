# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Camera effects active DURING the void chase sequence:
##   • Zooms out the camera for wider field of view.
##   • Applies continuous subtle camera shake.
## Returns to normal once chase ends.
## Connects to EnemyChaseTrigger and EnemyDefeatTrigger using [code]CameraShake[/code].

## Area that STARTS the chase (EnemyChaseTrigger).
@export var chase_start_area: Area2D
## Area that ENDS the chase (EnemyDefeatTrigger).
@export var chase_end_area: Area2D
## Camera zoom level during chase (smaller values = wider view).
@export var chase_zoom: Vector2 = Vector2(0.8, 0.8)
## Duration of zoom transition in seconds.
@export var zoom_time: float = 0.6
## Toggle camera shake during chase.
@export var enable_shake: bool = true
## Shake intensity.
@export var shake_intensity: float = 7.0
## Interval in seconds between continuous shake pulses.
@export var shake_interval: float = 0.8

var _cam: Camera2D
var _normal_zoom: Vector2 = Vector2.ZERO
var _shake_timer: Timer


func _ready() -> void:
	if is_instance_valid(chase_start_area):
		chase_start_area.body_entered.connect(_on_chase_start)
	if is_instance_valid(chase_end_area):
		chase_end_area.body_entered.connect(_on_chase_end)

	_shake_timer = Timer.new()
	_shake_timer.wait_time = shake_interval
	add_child(_shake_timer)
	_shake_timer.timeout.connect(_do_shake)


func _on_chase_start(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var cam := _resolve_cam()
	if cam:
		create_tween().tween_property(cam, "zoom", chase_zoom, zoom_time)
	if enable_shake:
		_do_shake()
		_shake_timer.start()


func _on_chase_end(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_shake_timer.stop()
	var cam := _resolve_cam()
	if cam and _normal_zoom != Vector2.ZERO:
		create_tween().tween_property(cam, "zoom", _normal_zoom, zoom_time)


func _do_shake() -> void:
	if CameraShake.shaker == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	CameraShake.shaker.target = cam
	CameraShake.shaker.shake(shake_intensity, shake_interval * 1.5)


func _resolve_cam() -> Camera2D:
	if not is_instance_valid(_cam):
		var player := get_tree().get_first_node_in_group(&"player") as Node
		if player:
			_cam = player.get_node_or_null(^"Camera2D") as Camera2D
	if _cam and _normal_zoom == Vector2.ZERO:
		_normal_zoom = _cam.zoom
	return _cam
