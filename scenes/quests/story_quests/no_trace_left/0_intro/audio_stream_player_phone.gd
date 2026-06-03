# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AudioStreamPlayer2D

func _ready() -> void:
	if $"../Cinematic".has_signal("cinematic_finished"):
		$"../Cinematic".cinematic_finished.connect(_end_cinematic)

func _end_cinematic() -> void:
	play()
