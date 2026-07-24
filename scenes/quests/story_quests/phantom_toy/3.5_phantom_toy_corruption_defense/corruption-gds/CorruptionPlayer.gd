# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Player
class_name CorruptionPlayer

var previous_positions := []


func physics_process(_delta):

	previous_positions.push_front(global_position)

	if previous_positions.size() > 30:
		previous_positions.pop_back()
