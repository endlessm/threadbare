# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Inkwell
extends StaticBody2D

signal completed

const INK_NEEDED: int = 3

@export var ink_color_name: InkBlob.InkColorNames = InkBlob.InkColorNames.CYAN:
	set = _set_ink_color_name

var ink_amount: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var color_label: Control = %ColorLabel


func _set_ink_color_name(new_ink_color_name: InkBlob.InkColorNames) -> void:
	ink_color_name = new_ink_color_name
	if not is_node_ready():
		return
	var color: Color = InkBlob.INK_COLORS[ink_color_name]
	animated_sprite_2d.modulate = color
	color_label.label_text = InkBlob.InkColorNames.keys()[ink_color_name]


func _ready() -> void:
	_set_ink_color_name(ink_color_name)


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
