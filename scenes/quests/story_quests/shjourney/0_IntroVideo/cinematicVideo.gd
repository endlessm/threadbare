# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@export var video_player: VideoStreamPlayer
@onready var next_scene_link: SceneLink = %NextSceneLink


func _ready() -> void:
	video_player.play()
	await video_player.finished
	next_scene_link.switch()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		next_scene_link.switch()
