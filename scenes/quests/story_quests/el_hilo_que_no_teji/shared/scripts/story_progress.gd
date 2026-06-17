# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends Node

const SATURATION_PER_THREAD := 0.07

static func get_current_saturation() -> float:
	var collected := GameState.items_collected().size()

	return clamp(
		collected * SATURATION_PER_THREAD,
		0.0,
		1.0
	)
