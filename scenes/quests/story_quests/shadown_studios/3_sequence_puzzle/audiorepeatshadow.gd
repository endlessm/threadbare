extends AudioStreamPlayer

func _ready():
	$AudioStreamPlayer.finished.connect(_on_finished)

func _on_finished():
	$AudioStreamPlayer.play()
