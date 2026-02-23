@tool
class_name Coin
extends Area2D

## Use this to change the texture of the coin.
@export var texture: Texture2D = _initial_texture:
	set = _set_texture

## Use this to tint the texture of the coin a different color.
@export var tint: Color = Color.WHITE:
	set = _set_tint

@onready var _sprite: Sprite2D = %Sprite2D
@onready var _initial_texture: Texture2D = %Sprite2D.texture
@onready var _collect_sound_player: AudioStreamPlayer2D = %CollectSoundPlayer


func _set_texture(new_texture: Texture2D):
	texture = new_texture

	if not is_node_ready():
		return

	if texture != null:
		_sprite.texture = texture
	else:
		_sprite.texture = _initial_texture
	notify_property_list_changed()


func _set_tint(new_tint: Color):
	tint = new_tint
	if is_node_ready():
		modulate = tint


func _ready():
	_set_texture(texture)
	_set_tint(tint)


func _on_body_entered(_body):
	Global.collect_coin()

	# Prevent collecting the coin a second time
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# TODO: Add a "collected" animation that plays alongside the sound?
	visible = false

	if _collect_sound_player:
		_collect_sound_player.play()
		await _collect_sound_player.finished

	queue_free()
