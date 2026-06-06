# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AudioStreamPlayer2D

func _ready() -> void:
	if $"../Cinematic".has_signal("cinematic_finished"):
		$"../Cinematic".cinematic_finished.connect(_start_phone)
	if $"../NtlPhone/InteractArea".has_signal("interaction_started"):
		$"../NtlPhone/InteractArea".interaction_started.connect(_end_phone)

func _start_phone() -> void:
	play()

func _end_phone(_player: Node, _from_right: bool) -> void:
	stop()
