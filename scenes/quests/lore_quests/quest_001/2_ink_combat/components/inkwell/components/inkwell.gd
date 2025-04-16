# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Inkwell
extends StaticBody2D

signal completed

const INK_NEEDED: int = 3

## Projectiles with this label fill the barrel.
@export var label: String = "???":
	set = _set_label

## Optional color to tint the barrel.
@export var color: Color:
	set = _set_color

var ink_amount: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var color_label: Control = %ColorLabel


func _set_label(new_label: String) -> void:
	label = new_label
	if not is_node_ready():
		return
	if label:
		color_label.label_text = label
	else:
		color_label.label_text = "???"


func _set_color(new_color: Color) -> void:
	color = new_color
	if not is_node_ready():
		return
	if color:
		animated_sprite_2d.modulate = color
	else:
		animated_sprite_2d.modulate = Color.WHITE


func _ready() -> void:
	_set_label(label)
	_set_color(color)


func fill() -> void:
	animation_player.play(&"fill")
	ink_amount += 1
	animated_sprite_2d.frame += 1
	if ink_amount >= INK_NEEDED:
		await animation_player.animation_finished
		animation_player.play(&"completed")
		await animation_player.animation_finished
		queue_free()
		completed.emit()
