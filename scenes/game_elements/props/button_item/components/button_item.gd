# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name ButtonItem
extends Node2D
## @experimental
##
## A button that dissapears on contact with Player.
##
## Visually it's built with 2 sprites:[br]
## • The button sprite.[br]
## • The shadow sprite.
## [br][br]
## Both sprites have a frame-by-frame animation, but only the button sprite
## has its position animated through an AnimationPlayer to move up and down.
## Thus the separation. The up and down animation is shifted according to
## the global position, for variety.

## Emitted when the button touches the player hitbox.
signal collected

@onready var _up_down_animation: AnimationPlayer = %UpDownAnimation


func _ready() -> void:
	# Delay the up and down animation according to the global position,
	# so multiple buttons in a row form a wave:
	var t: float = (sin(global_position.x) + 1) * 0.5 + (cos(global_position.y) + 1) * 0.5
	_up_down_animation.seek(_up_down_animation.current_animation_length * t)


func _on_area_2d_area_entered(area: Area2D) -> void:
	# TODO: This is not added to an inventory or anything, is just cosmetic.
	if area.owner.is_in_group(&"player"):
		collected.emit()
		queue_free()
