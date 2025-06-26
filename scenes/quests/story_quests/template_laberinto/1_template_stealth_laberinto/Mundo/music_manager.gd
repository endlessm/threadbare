extends Node

@export var music_tracks: Array[AudioStream] = []
@export var music_special: AudioStream

var current_index := 0
var player := AudioStreamPlayer.new()
var playing_special := false

func _ready():
	add_child(player)
	player.finished.connect(_on_music_finished)
	if music_tracks.size() > 0:
		play_next()

func play_next():
	if playing_special:
		return
	if music_tracks.size() == 0:
		return
	player.stream = music_tracks[current_index]
	player.play()
	current_index = (current_index + 1) % music_tracks.size()

func _on_music_finished():
	if not playing_special:
		play_next()
	else:
		playing_special = false
		current_index = 0
		play_next()

func play_special(track: AudioStream):
	if not track:
		return
	playing_special = true
	player.stream = track
	player.play()
