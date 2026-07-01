# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label
@export var timer_path: NodePath

var timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = get_node(timer_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = str(int(ceil(timer.time_left)))
