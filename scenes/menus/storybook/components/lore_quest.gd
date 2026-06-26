# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name LoreQuest
extends Quest
## A quest that is part of the main game lore.

## Whether this quest is skippable (i.e. is the tutorial)
@export var skippable: bool = false:
	set(new_value):
		skippable = new_value
		notify_property_list_changed()

## Which abilities to award if the quest is skipped
@export var skip_abilities: Array[Enums.PlayerAbilities] = []


func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)

	match property["name"]:
		"skip_abilities":
			if not skippable:
				property.usage = PROPERTY_USAGE_NONE
