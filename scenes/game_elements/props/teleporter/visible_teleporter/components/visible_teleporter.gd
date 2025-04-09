# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Teleporter

@onready var blue_fire: AnimatedSprite2D = %BlueFire


func _ready() -> void:
	super._ready()
	blue_fire.play("burning")
