extends Node2D
@export var video_player: VideoStreamPlayer 
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
