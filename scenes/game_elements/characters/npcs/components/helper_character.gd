# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## @experimental
##
## Makes a CharacterRandomizer a helper.
##
## If the global game state has help of the same type, the character becomes visible and
## interactible, using the persisted character seed and ready to help the player.
## Otherwise, it remains hidden and deactivated.
## The help itself must be implemented per scene on the instantiated character.

## The helper type to match.
@export var helper_type: InventoryItem.ItemType = InventoryItem.ItemType.MEMORY

## The CharacterRandomizer that will offer help.
@onready var character: CharacterRandomizer = get_parent()


func _ready() -> void:
	GameState.global.helper.changed.connect(_on_helper_state_changed)
	_on_helper_state_changed()


func _on_helper_state_changed() -> void:
	var is_enabled := (
		helper_type == GameState.global.helper.helper_type
		and bool(GameState.global.helper.character_seed)
	)
	character.visible = is_enabled
	character.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
	if is_enabled:
		character.character_seed = GameState.global.helper.character_seed
		character.apply_character_randomizations()
