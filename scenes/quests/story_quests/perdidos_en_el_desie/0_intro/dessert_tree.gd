# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Reemplaza "idle" por el nombre exacto de tu animación
	play("default")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	pass
