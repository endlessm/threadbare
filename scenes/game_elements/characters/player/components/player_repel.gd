# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PlayerRepel
extends Node2D

## Emitted when the repel starts or stops.
signal repelling_changed(repelling: bool)

## Current state of the repel.
var repelling: bool = false:
	set = _set_repelling

@onready var air_stream: Area2D = %AirStream

@onready var player: Player = self.owner as Player


func _set_repelling(new_repelling: bool) -> void:
	repelling = new_repelling
	repelling_changed.emit(repelling)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"repel"):
		repelling = true
	elif Input.is_action_just_released(&"repel"):
		repelling = false


func _on_air_stream_body_entered(body: Projectile) -> void:
	body.got_hit(owner)
