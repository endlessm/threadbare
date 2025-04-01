# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


func _ready() -> void:
	hide()


func _on_music_puzzle_solved() -> void:
	show()
	play()
