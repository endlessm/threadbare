# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
@export var animacion : AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacion.play("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
