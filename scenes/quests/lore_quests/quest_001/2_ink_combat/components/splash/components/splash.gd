# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


func _ready() -> void:
	play(&"default")
	animation_looped.connect(_on_end)


func _on_end() -> void:
	queue_free()
