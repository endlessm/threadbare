# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D

@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D


func _ready() -> void:
	hide()
	collision_shape_2d.disabled = true


func _show() -> void:
	collision_shape_2d.disabled = false
	show()
	play()


func _on_ink_combat_finished() -> void:
	_show.call_deferred()
