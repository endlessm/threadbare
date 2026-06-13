class_name Altar
extends Node2D

@export var clean_texture: Texture2D
@export var corrupted_texture: Texture2D

var is_corrupted := false
var cleaning_started := false

@onready var sprite: Sprite2D = $Sprite2D

@onready var corrupt_sound: AudioStreamPlayer2D = $CorruptSound
@onready var purify_sound: AudioStreamPlayer2D = $PurifySound


func set_corrupted(value: bool) -> void:

	if not is_node_ready():
		await ready

	if value:

		cleaning_started = false
		is_corrupted = true

		sprite.texture = corrupted_texture

		corrupt_sound.stop()
		corrupt_sound.play()

	else:

		if not is_corrupted:
			return

		if cleaning_started:
			return

		cleaning_started = true

		_delayed_clean()


func _delayed_clean() -> void:

	await get_tree().create_timer(0.3).timeout

	sprite.texture = clean_texture

	purify_sound.stop()
	purify_sound.play()

	is_corrupted = false
	cleaning_started = false
