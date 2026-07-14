# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
@onready var repel_timer: Timer = %RepelTimer
@onready var repel_timer_2: Timer = $Sheep2/PlayerRepel2/RepelTimer2


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if repel_timer_2.is_node_ready():
		await get_tree().create_timer(.5).timeout
		repel_timer.start()
