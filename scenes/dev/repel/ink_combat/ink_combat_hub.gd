# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var fragile_barrel: FragileBarrel = %FragileBarrel


func _ready() -> void:
	# Update animation frame to show cracked barrel
	var crack_overlay = fragile_barrel.get_node("%CrackOverlay")
	crack_overlay.visible = true
	crack_overlay.frame = 3
