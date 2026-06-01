# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name HelperCharacterState
extends Resource

## The type of help, matching the magical threads type.
## This is left to game designers interpretation but usually:
## [br][br]
## - Memory is about expanding the lore of the game.[br]
## - Imagination is about making things appear in the level.[br]
## - Spirit is about reducing the difficulty of an action-based puzzle.[br]
@export var helper_type: InventoryItem.ItemType = InventoryItem.ItemType.NONE

## The seed to display a character with same visual features when offering help.
@export var character_seed: int = 0


## Consume the help.
func clear() -> void:
	helper_type = InventoryItem.ItemType.NONE
	character_seed = 0
	emit_changed()


## Obtain the help.
func obtain(new_helper_type: InventoryItem.ItemType, new_character_seed: int) -> void:
	helper_type = new_helper_type
	character_seed = new_character_seed
	emit_changed()
