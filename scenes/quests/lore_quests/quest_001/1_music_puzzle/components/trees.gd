# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

const ALTERNATIVE_PERCENTAGE: float = 0.4

const ALTERNATIVE_SPRITEFRAMES = preload("uid://djwymcffy83")
const SPRITEFRAMES = preload("uid://d36eq8tqdaxdy")

@export_tool_button("Randomize Trees Appearances") var a = func():
	for child in get_children():
		child.set(
			"sprite_frames",
			SPRITEFRAMES if randf() > ALTERNATIVE_PERCENTAGE else ALTERNATIVE_SPRITEFRAMES
		)
