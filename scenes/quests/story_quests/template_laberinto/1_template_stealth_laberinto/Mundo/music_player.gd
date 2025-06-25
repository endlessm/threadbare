extends AudioStreamPlayer

@export var music_list: Array[AudioStream] = []
var current_index := 0

func _ready():
	if music_list.size() > 0:
		stream = music_list[current_index]
		play()
		connect("finished", Callable(self, "_on_music_finished"))

func _on_music_finished():
	current_index = (current_index + 1) % music_list.size()
	stream = music_list[current_index]
	play()
