# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"


func _process(_delta: float) -> void:
	var time := animation_player.current_animation_position
	var period: String
	if time > 5 and time <= 12:
		period = "morning"
	elif time > 12 and time <= 18:
		period = "afternoon"
	elif time > 18 and time <= 22:
		period = "evening"
	else:
		period = "night"
	text = "%.1f %s" % [time, period]
