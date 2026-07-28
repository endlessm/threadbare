# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Cutscene
extends Node2D

signal finished

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	animation_player.play("reweaven")
	await animation_player.animation_finished
	finished.emit()
