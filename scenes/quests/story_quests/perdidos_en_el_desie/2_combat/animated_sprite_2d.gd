# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Esta es la línea mágica que hace que el mago empiece a animarse
	play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
