extends AnimatedSprite2D


func _ready() -> void:
	hide()


func _on_music_puzzle_solved() -> void:
	show()
	play()
