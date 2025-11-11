extends Control
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	video_stream_player.play()
	pass
	
