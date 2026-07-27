# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends ProgressBar
## Visualises the progress of a Timer.
##
## Removes itself from the tree when the timer expires or is stopped.

@export var timer: Timer


func _ready() -> void:
	max_value = timer.wait_time


func _process(_delta: float) -> void:
	if timer.paused or timer.is_stopped():
		queue_free()
	else:
		value = timer.wait_time - timer.time_left
