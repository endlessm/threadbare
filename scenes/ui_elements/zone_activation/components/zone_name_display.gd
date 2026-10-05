# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PanelContainer

@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func animate(zone_name: String) -> void:
	label.text = zone_name
	animation_player.play(&"default")
