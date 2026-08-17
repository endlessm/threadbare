# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends StaticBody2D

@export var start_position: Vector2
@export var end_position: Vector2
@export var start_dialogue: DialogueResource
@export var end_dialogue: DialogueResource

@onready var talk_behavior: TalkBehavior = $TalkBehavior


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = start_position
	talk_behavior.dialogue = start_dialogue


## When a puzzle is solved, this changes the skeleton's position and their dialogue
func puzzle_solved():
	position = end_position
	talk_behavior.dialogue = end_dialogue


func _on_statue_puzzle_solved() -> void:
	pass # Replace with function body.
	position = end_position
	talk_behavior.dialogue = end_dialogue

func _hidden() -> void:
	pass # Replace with function body.
	position = end_position
	talk_behavior.dialogue = end_dialogue


func _on_sequence_puzzle_step_4_hidden() -> void:
	pass # Replace with function body.
	position = end_position
	talk_behavior.dialogue = end_dialogue
