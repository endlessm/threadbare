# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Splash
extends AnimatedSprite2D

@export var ink_color_name: Projectile.InkColorNames = Projectile.InkColorNames.CYAN


func _ready() -> void:
	var color: Color = Projectile.INK_COLORS[ink_color_name]
	modulate = color
	play(&"default")
	animation_looped.connect(_on_end)


func _on_end() -> void:
	queue_free()
