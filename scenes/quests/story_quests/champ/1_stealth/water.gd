# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# pick random animation for variance
	var animations = ["1","2","3"]
	play(animations.pick_random())
