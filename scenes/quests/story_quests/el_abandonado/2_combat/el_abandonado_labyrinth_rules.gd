# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

@export var player_path: NodePath = ^"../Player"
@export var timer_path: NodePath = ^"../Timer"
@export var cinematic_path: NodePath = ^"../Cinematic"
@export var start_timer_after_cinematic: bool = true

@onready var _player: Node2D = get_node(player_path)
@onready var _timer: Timer = get_node(timer_path)
@onready var _cinematic: Cinematic = get_node(cinematic_path)

var _mushroom_camera_tween: Tween
var _mushroom_effect_token: int = 0


func _ready() -> void:
	add_to_group(&"el_abandonado_labyrinth_rules")
	_ensure_player_camera()
	_start_countdown_timer()


func _ensure_player_camera() -> void:
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()


func _start_countdown_timer() -> void:
	if not start_timer_after_cinematic or not is_instance_valid(_cinematic):
		_timer.start()
		return

	if GameState.intro_dialogue_shown:
		_timer.start()
		return

	_cinematic.cinematic_finished.connect(_timer.start, CONNECT_ONE_SHOT)


func _on_timer_timeout() -> void:
	if _player.has_method("defeat"):
		_player.defeat()
	else:
		push_warning("Detected node does not have defeat() method: %s" % _player)


func activate_mushroom_vision(
	camera: Camera2D,
	zoom: Vector2,
	view_duration: float,
	transition_time: float
) -> void:
	if not is_instance_valid(camera):
		return

	camera.make_current()
	_run_mushroom_vision(camera, zoom, view_duration, transition_time)


func _run_mushroom_vision(
	camera: Camera2D,
	zoom: Vector2,
	view_duration: float,
	transition_time: float
) -> void:
	_mushroom_effect_token += 1
	var current_token := _mushroom_effect_token
	var original_zoom := camera.zoom

	if _mushroom_camera_tween and _mushroom_camera_tween.is_running():
		_mushroom_camera_tween.kill()

	_mushroom_camera_tween = create_tween()
	_mushroom_camera_tween.set_trans(Tween.TRANS_SINE)
	_mushroom_camera_tween.set_ease(Tween.EASE_OUT)
	_mushroom_camera_tween.tween_property(camera, "zoom", zoom, transition_time)

	await _mushroom_camera_tween.finished

	if current_token != _mushroom_effect_token:
		return

	await get_tree().create_timer(view_duration).timeout

	if current_token != _mushroom_effect_token:
		return

	if _mushroom_camera_tween and _mushroom_camera_tween.is_running():
		_mushroom_camera_tween.kill()

	_mushroom_camera_tween = create_tween()
	_mushroom_camera_tween.set_trans(Tween.TRANS_SINE)
	_mushroom_camera_tween.set_ease(Tween.EASE_OUT)
	_mushroom_camera_tween.tween_property(camera, "zoom", original_zoom, transition_time)
