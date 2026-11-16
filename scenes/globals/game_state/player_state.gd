# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name PlayerState
extends Resource

## Emitted when [member abilities] changes
signal abilities_changed

const MAX_LIVES := 2 ** 53

## Current number of lives the player has.
@export_range(0, MAX_LIVES, 1) var lives: int = MAX_LIVES:
	set(value):
		lives = value
		changed.emit()

## Bitfield of elements of Enums.PlayerAbilities
@export var abilities: int:
	set(value):
		if abilities != value:
			abilities = value
			changed.emit()
			abilities_changed.emit()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"player_abilities":
			property.hint = PROPERTY_HINT_FLAGS
			# This is not a constant expression, so we cannot use @export_custom
			property.hint_string = ",".join(Enums.PlayerAbilities.keys())


## Reduces [member lives] by 1.
func decrement_lives() -> void:
	lives = max(0, lives - 1)


## Resets [member lives] to [const MAX_LIVES].
func reset_lives() -> void:
	lives = MAX_LIVES


## Enable or disable a player ability.
func set_ability(ability: Enums.PlayerAbilities, is_enabled: bool) -> void:
	if is_enabled:
		abilities |= ability
	else:
		abilities &= ~ability


## Check if a player ability is enabled.
## [br][br]
## This will behave differently in the main "lore" game than in
## StoryQuests: the lore has player progression that last the whole game,
## while StoryQuests are narrative units and have their own player progression.
func has_ability(ability: Enums.PlayerAbilities) -> bool:
	return abilities & ability
