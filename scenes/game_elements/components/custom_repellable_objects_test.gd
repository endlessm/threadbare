# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var repel_timer: Timer = %RepelTimer


func _on_repellable_lever_2_toggled(is_on: bool) -> void:
	if not is_node_ready():
		return
	if is_on and repel_timer.is_stopped():
		repel_timer.start()
	elif not is_on and not repel_timer.is_stopped():
		repel_timer.stop()
