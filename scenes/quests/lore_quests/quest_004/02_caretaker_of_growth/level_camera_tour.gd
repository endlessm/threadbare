# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

@onready var _player: CharacterBody2D = $"../OnTheGround/Player"
@onready var _camera: Camera2D = $"../OnTheGround/Player/Camera2D"
@onready var _fade_overlay: ColorRect = $"../ScreenFader/FadeOverlay"
@onready var _butterfly: CharacterBody2D = $"../Butterfly"


func _ready() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_butterfly.set_physics_process(false)
	play("intro_tour")
	animation_finished.connect(_on_tour_finished)


func _unhandled_input(event: InputEvent) -> void:
	if is_playing() and (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact")):
		stop()
		_on_tour_finished("intro_tour")


func _on_tour_finished(_anim_name: StringName) -> void:
	_camera.position = Vector2.ZERO
	_camera.zoom = Vector2(1.1, 1.1)
	_fade_overlay.visible = false
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_butterfly.set_physics_process(true)
