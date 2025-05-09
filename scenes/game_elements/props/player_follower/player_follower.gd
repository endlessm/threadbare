# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends PathFollow2D

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	progress = get_parent().curve.get_closest_offset(get_parent().to_local(player.global_position))
