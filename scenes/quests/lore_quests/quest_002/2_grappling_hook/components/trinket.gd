# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var trinket: Trinket


func _ready() -> void:
	if GameState.has_trinket(trinket.id):
		queue_free()


func _on_interact_area_interaction_started(area: InteractArea) -> void:
	GameState.add_trinket(trinket)
	queue_free()
	area.end_interaction()
