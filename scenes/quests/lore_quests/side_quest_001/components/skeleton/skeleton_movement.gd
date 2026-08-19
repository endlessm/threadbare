# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

@export var start_position: Vector2
@export var end_position: Vector2
@export var start_dialogue: DialogueResource
@export var end_dialogue: DialogueResource

var already_teleported: bool = false

@onready var talk_behavior: TalkBehavior = $TalkBehavior


## Sets the starting position and dialogue of the skeleton.
func _ready() -> void:
	position = start_position
	talk_behavior.dialogue = start_dialogue


## When a puzzle is solved, this changes the skeleton's position and their dialogue.
func puzzle_solved() -> void:
	if not already_teleported:
		position = end_position
		talk_behavior.dialogue = end_dialogue
		already_teleported = true


## When the player begins to read the bool, call the function that moves the skeleton.
func _on_interaction_started(_player: Player, _from_right: bool) -> void:
	puzzle_solved()
