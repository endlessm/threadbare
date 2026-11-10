# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func stop_animation() -> void:
	if animation_player.is_playing():
		animation_player.stop()


func animate(zone_name: String) -> void:
	stop_animation()
	label.text = zone_name
	animation_player.play(&"default")
