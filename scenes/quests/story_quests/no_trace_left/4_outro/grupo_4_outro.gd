# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var mercader = $OnTheGround/Mercader
func _ready() -> void:
	mercader_animation()

func mercader_animation():
	mercader.play("idle")
