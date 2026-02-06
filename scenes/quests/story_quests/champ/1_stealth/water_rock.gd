# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		# randomize starting frame for visual variance
		var rng : RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		frame = rng.randi_range(0,7)
		
		play("water_rock")
	
