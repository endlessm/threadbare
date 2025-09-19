# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
# TODO: Prepend "abstract" when switching to Godot 4.5:
class_name BaseCharacterBehavior
extends Node2D
## @experimental
##
## Base class for character behaviors.

## The controlled character.[br][br]
##
## [b]Note:[/b] If the parent node is a CharacterBody2D and character isn't set,
## the parent node will be automatically assigned to this variable.
@export var character: CharacterBody2D:
	set = _set_character


func _enter_tree() -> void:
	if not character and get_parent() is CharacterBody2D:
		character = get_parent()


func _set_character(new_character: CharacterBody2D) -> void:
	character = new_character
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not character:
		warnings.append("Character must be set.")
	return warnings
