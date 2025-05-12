# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name BonfireSign
extends StaticBody2D

enum Sign { FORWARD, BACK, BACK_UP, FORWARD_UP }

@export var puzzle: MusicPuzzle

@export var sign: Sign = Sign.FORWARD:
	set(new_sign):
		sign = new_sign
		update_sign_sprite()

@export var is_ignited: bool = false:
	set(new_val):
		is_ignited = new_val
		update_ignited_state()

## If true, the player can interact with the sign to hear its melody, even when the fire is not
## ignited. If false, the player must play the melody correctly before they are able to interact
## with the fire to get a reminder of the melody they played.
@export var can_interact_when_unlit: bool = true:
	set(new_value):
		can_interact_when_unlit = new_value
		update_ignited_state()

@onready var fire: AnimatedSprite2D = %Fire
@onready var interact_area: InteractArea = %InteractArea
@onready var sign_sprite: AnimatedSprite2D = %SignSprite

@onready var fire_start_sound: AudioStreamPlayer2D = %FireStartSound
@onready var fire_continuous_sound: AudioStreamPlayer2D = %FireContinuousSound


func _ready() -> void:
	update_ignited_state()


func update_ignited_state() -> void:
	var was_node_ready: bool = is_node_ready()
	if not was_node_ready:
		await ready
	fire.play(&"burning" if is_ignited else &"default")
	interact_area.disabled = not (puzzle and (is_ignited or can_interact_when_unlit))
	## We don't want to play the fire start sound if the bonfire started on.
	fire_start_sound.playing = is_ignited and was_node_ready
	fire_continuous_sound.playing = is_ignited

	update_sign_sprite()


func ignite() -> void:
	is_ignited = true


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	await puzzle.play_demo_melody_of_fire(self)
	interact_area.end_interaction()


func update_sign_sprite() -> void:
	if !is_instance_valid(sign_sprite):
		return
	var suffix: String = "on" if is_ignited else "off"
	var sign_string: String = Sign.find_key(sign)

	sign_sprite.animation = "%s_%s" % [sign_string.to_snake_case(), suffix]
