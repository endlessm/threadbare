# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

signal matching
signal exited(matches: bool)

## Expected symbol is the symbol the statue must have in order to match.
@export var expected_symbol: String
@export var sprite: Texture2D:
	set = _set_sprite

## Keeps track of whether the statue that is on it has a matching symbol.
var matched: bool = false
## Keeps track of whether there is something on the pressure plate.
var something_in: bool = false

@onready var appearance: Sprite2D = $Sprite2D


## Automatically sets the sprite.
func _ready() -> void:
	_set_sprite(sprite)


## Checks if a statue is on the pressure plate and if it matches the corresponding symbol.
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Must check if something is not inside first to avoid multiple items changing the values
	if not something_in:
		if body.is_in_group("statues"):
			something_in = true
			var sym: String = body.get_symbol()
			if sym == expected_symbol:
				matching.emit()
				matched = true
			else:
				matched = false


## Checks if a statue is off the pressure plate.
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Must check if something is not inside first to avoid multiple items changing the values
	if something_in:
		if body.is_in_group("statues"):
			something_in = false
			exited.emit(matched)
			matched = false


## The actual method that sets up the sprite chosen in the editor.
func _set_sprite(look: Texture2D) -> void:
	sprite = look
	if appearance:
		appearance.texture = look
