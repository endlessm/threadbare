# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var game_logic: Node

func _ready() -> void:
	if is_instance_valid(game_logic) and game_logic.has_signal("goal_reached"):
		game_logic.goal_reached.connect(_on_puzzle_completado)

func _on_puzzle_completado() -> void:
	hide() # Oculta la barrera y sus sprites
	
	var static_body: StaticBody2D = $StaticBody2D
	if is_instance_valid(static_body):
		static_body.collision_layer = 0
		static_body.collision_mask = 0
		
	var colision: Node = $StaticBody2D.get_child(0)
	if is_instance_valid(colision):
		colision.set_deferred("disabled", true)
