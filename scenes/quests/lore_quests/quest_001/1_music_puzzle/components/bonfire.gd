# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Bonfire
extends StaticBody2D

# This is a NodePath instead of just a node reference to be able to initialize it to ..
@export_node_path("MusicPuzzle") var puzzle_path: NodePath = ^".."

@onready var fire: AnimatedSprite2D = %Fire
@onready var interact_area: InteractArea = %InteractArea

@onready var puzzle: MusicPuzzle = get_node(puzzle_path)


func ignite() -> void:
	fire.play(&"burning")
	interact_area.disabled = false


func _on_interact_area_interaction_started(_player: Player, _from_right: bool) -> void:
	await puzzle.play_demo_melody_of_fire(self)
	interact_area.end_interaction()
