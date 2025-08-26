# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
## Shows a dialogue, then transitions to another scene.
## Intended for use in non-interactive cutscenes, such as the intro and outro to a quest
class_name CinematicVideo
extends Node2D
@export var video_player: VideoStreamPlayer


## Dialogue for cinematic scene

## Animation player, to be used from [member dialogue] (if needed)
@export var animation_player: AnimationPlayer

## Scene to switch to once [member dialogue] is complete
@export_file("*.tscn") var next_scene: String

## Optional path inside [member next_scene] where the player should appear.
## If blank, player appears at default position in the scene. If in doubt,
## leave this blank.
@export var spawn_point_path: String


func _ready() -> void:
	video_player.play()
	await video_player.finished

	if next_scene:
		(
			SceneSwitcher
			. change_to_file(
				next_scene,
				spawn_point_path,
			)
		)
