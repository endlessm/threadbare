# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@export var expected_symbol: String

signal matching
signal exited(matches: bool)

var matched: bool = false
var something_in: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Checks if a statue is on the pressure plate and if it matches the corresponding symbol
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Must check if something is not inside first to avoid multiple items changing the values
	if not something_in:
		if body.is_in_group("statues"):
			something_in = true
			var sym = body.get_symbol()
			if sym == expected_symbol:
				matching.emit()
				matched = true
				print("matches")
			else:
				matched = false
				print("not matches")
		else:
			print("nah")

## Checks if a statue is off the pressure plate
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Must check if something is not inside first to avoid multiple items changing the values
	if something_in:
		if body.is_in_group("statues"):
			something_in = false
			exited.emit(matched)
			matched = false
			print("out")
		else:
			print("nah 2")
