# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func reveal() -> void:
	animation_player.play("reveal")
