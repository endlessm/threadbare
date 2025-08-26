extends AudioStreamPlayer2D

func _ready() -> void:
	play()
	finished.connect(_on_audio_finished)

func _on_audio_finished():
	play()
