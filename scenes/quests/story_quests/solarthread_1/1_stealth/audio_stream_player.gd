extends Node

@onready var music = $AudioStreamPlayer

func _ready():
	# Empieza a reproducir
	music.play()
	# Cuando termina, vuelve a empezar
	music.finished.connect(_on_music_finished)

func _on_music_finished():
	music.play()
