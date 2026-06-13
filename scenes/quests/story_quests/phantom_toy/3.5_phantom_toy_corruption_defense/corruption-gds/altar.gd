class_name Altar
extends Node2D

@export var clean_texture: Texture2D
@export var corrupted_texture: Texture2D

var is_corrupted := false
var cleaning_started := false

@onready var sprite: Sprite2D = $Sprite2D

@onready var corrupt_sound: AudioStreamPlayer2D = $CorruptSound
@onready var purify_sound: AudioStreamPlayer2D = $PurifySound


func set_corrupted(value: bool, play_sound := true) -> void:

	if not is_node_ready():
		await ready

	if value:

		cleaning_started = false
		is_corrupted = true

		sprite.texture = corrupted_texture

		if play_sound:
			play_corruption_sound()

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

	is_corrupted = false
	cleaning_started = false


func play_corruption_sound() -> void:

	if not is_node_ready():
		await ready

	if corrupt_sound == null:
		return

	if not corrupt_sound.playing:
		corrupt_sound.play()


func stop_corruption_sound() -> void:

	if not is_node_ready():
		await ready

	if corrupt_sound == null:
		return

	corrupt_sound.stop()


func play_purification_sound() -> void:

	if not is_node_ready():
		await ready

	if purify_sound == null:
		return

	if not purify_sound.playing:
		purify_sound.play()


func stop_purification_sound() -> void:

	if not is_node_ready():
		await ready

	if purify_sound == null:
		return

	purify_sound.stop()


func stop_all_sounds() -> void:

	if not is_node_ready():
		await ready

	if corrupt_sound != null:
		corrupt_sound.stop()

	if purify_sound != null:
		purify_sound.stop()
