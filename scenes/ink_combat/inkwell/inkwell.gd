# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Inkwell
extends StaticBody2D

signal completed

const INK_NEEDED: int = 3

@export var ink_color_name: InkBlob.InkColorNames = InkBlob.InkColorNames.CYAN

var ink_amount: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var color_label: Control = %ColorLabel


func _ready() -> void:
	var color: Color = InkBlob.INK_COLORS[ink_color_name]
	animated_sprite_2d.modulate = color

	color_label.label_text = InkBlob.InkColorNames.keys()[ink_color_name]


func fill() -> void:
	animation_player.play(&"fill")
	ink_amount += 1
	animated_sprite_2d.frame += 1
	if ink_amount >= INK_NEEDED:
		queue_free()
		completed.emit()
