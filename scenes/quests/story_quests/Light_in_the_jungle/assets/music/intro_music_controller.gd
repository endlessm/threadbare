# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

@export_tool_button("Play") var play_button: Callable = _play
@export_tool_button("Stop") var stop_button: Callable = _stop
@export_tool_button("Pause/Resume") var pause_resume_button: Callable = _pause_resume

# Streams de audio
@export var intro_part01: AudioStream
@export var intro_part02: AudioStream
@export var transition_dialogue: DialogueResource  # El diálogo que activa la transición

@onready var audio_stream_player: AudioStreamPlayer = MusicPlayer.background_music_player

var is_transitioning: bool = false
var part01_finished: bool = false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not intro_part01:
		warnings.append("intro_part01 audio stream is not set!")
	
	if not intro_part02:
		warnings.append("intro_part02 audio stream is not set!")
		
	if not transition_dialogue:
		warnings.append("transition_dialogue is not set!")

	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Conectar al DialogueManager para escuchar cuando termine el diálogo específico
	if transition_dialogue:
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Empezar con la primera parte
	if intro_part01:
		_fade_in()
		_play_part01()
	else:
		_stop()

	Transitions.started.connect(self._fade_out)


func _play() -> void:
	if not part01_finished:
		_play_part01()
		# Asegurar volumen completo para la parte 1
		audio_stream_player.volume_db = linear_to_db(1.0)
	else:
		_play_part02()
		# El volumen ya se establece dentro de _play_part02()


func _play_part01() -> void:
	if audio_stream_player.stream == intro_part01 and audio_stream_player.playing:
		return

	if intro_part01:
		audio_stream_player.stream = intro_part01
		audio_stream_player.play()


func _play_part02() -> void:
	if audio_stream_player.stream == intro_part02 and audio_stream_player.playing:
		return

	if intro_part02:
		audio_stream_player.stream = intro_part02
		audio_stream_player.play()
		# Establecer volumen al 75% para la parte 2
		audio_stream_player.volume_db = linear_to_db(0.75)


func _stop() -> void:
	audio_stream_player.stop()


func _pause_resume() -> void:
	if audio_stream_player.is_playing():
		audio_stream_player.stream_paused = true
	else:
		audio_stream_player.stream_paused = false


func _fade_in() -> void:
	create_tween().tween_property(audio_stream_player, "volume_db", linear_to_db(1.0), 1.0)


func _fade_out() -> void:
	# If we use linear_to_db(0.0) as final value, the audio stream player
	# is muted instantly because it goes from 0.0db to -infdb.
	create_tween().tween_property(audio_stream_player, "volume_db", linear_to_db(0.00001), 1.0)


func _on_dialogue_ended(dialogue_resource: DialogueResource) -> void:
	# Solo hacer la transición si es el diálogo específico que esperamos
	if dialogue_resource == transition_dialogue and not part01_finished:
		print("IntroMusicController: Diálogo de intro terminado, iniciando transición musical")
		part01_finished = true
		_transition_to_part02()


func _transition_to_part02() -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	
	# Fade out de la parte 1
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(audio_stream_player, "volume_db", linear_to_db(0.00001), 1.0)
	await fade_out_tween.finished
	
	# Cambiar a la parte 2 y hacer fade in al 75%
	_play_part02()
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(audio_stream_player, "volume_db", linear_to_db(0.75), 1.0)
	await fade_in_tween.finished
	
	is_transitioning = false


func _exit_tree() -> void:
	## Without this, if you click the Play button and then close the scene
	## in the editor, the music will keep playing.
	if Engine.is_editor_hint():
		_stop()
