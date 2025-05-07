# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var is_hidden: bool = false:
	set(val):
		var was_hidden: bool = is_hidden
		is_hidden = val
		if is_hidden != was_hidden:
			_update_hidden_state()
			notify_property_list_changed()

@export var stay_hidden_or_revealed: bool = false

var _reveal_when_player_nearby: bool = false
var _hide_when_player_nearby: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _hide() -> void:
	animated_sprite_2d.play(&"hide")
	await animated_sprite_2d.animation_finished
	if animated_sprite_2d.animation == &"hide":
		animated_sprite_2d.visible = false


func _reveal() -> void:
	animated_sprite_2d.visible = true
	animated_sprite_2d.play(&"reveal")
	await animated_sprite_2d.animation_finished
	if animated_sprite_2d.animation == &"reveal":
		animated_sprite_2d.play(&"idle")


func _update_hidden_state() -> void:
	if !animated_sprite_2d:
		return

	if is_hidden:
		_hide()
	else:
		_reveal()


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "_reveal_when_player_nearby" if is_hidden else "_hide_when_player_nearby",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
		}
	]


func _reveal_or_hide(is_player_nearby: bool) -> void:
	if _reveal_when_player_nearby:
		is_hidden = not is_player_nearby
	elif _hide_when_player_nearby:
		is_hidden = is_player_nearby


func _ready() -> void:
	if is_hidden:
		animated_sprite_2d.visible = false


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_reveal_or_hide(true)


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player") and not stay_hidden_or_revealed:
		_reveal_or_hide(false)
