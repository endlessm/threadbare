# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var puzzle: Node = $OnTheGround/SequencePuzzle
func _ready() -> void:
	if puzzle.has_signal("step_solved"):
		print("paso correcto!!")
	if puzzle.has_signal("solved"):
		print("puzzle completado!!")
