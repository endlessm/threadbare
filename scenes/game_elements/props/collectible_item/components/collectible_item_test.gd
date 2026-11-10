# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var memory_unrevealed: CollectibleItem = %MemoryUnrevealed
@onready var imagination_unrevealed: CollectibleItem = %ImaginationUnrevealed
@onready var spirit_unrevealed: CollectibleItem = %SpiritUnrevealed


func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	memory_unrevealed.reveal()
	await get_tree().create_timer(5.0).timeout
	imagination_unrevealed.reveal()
	await get_tree().create_timer(5.0).timeout
	spirit_unrevealed.reveal()
