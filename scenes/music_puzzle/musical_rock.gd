class_name MusicalRock
extends StaticBody2D

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer

## Note in a major scale. 1 = root note, 8 = octave above.
@export_range(1, 8) var note: int = 1:
	set(_new_value):
		note = _new_value
		_modulate_rock()

@export var audio_stream: AudioStream

func _ready() -> void:
	_modulate_rock()
	audio_stream_player_2d.stream = audio_stream


func _modulate_rock():
	if sprite_2d:
		sprite_2d.modulate = Color.from_hsv((note - 1) * 100.0 / 7, 0.67, 0.89)


func _on_interaction_started() -> void:
	animation_player.play(&"wobble")
	audio_stream_player_2d.play()
	await audio_stream_player_2d.finished
	animation_player.play(&"RESET")
	interact_area.interaction_ended.emit.call_deferred()
