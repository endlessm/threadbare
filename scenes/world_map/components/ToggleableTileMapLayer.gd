# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ToggleableTileMapLayer
extends Toggleable
## Use a [TileMapLayer] as an unlockable door/barrier
##
## A [Toggleable] that disables a [TileMapLayer] when enabled, and enables it
## when disabled. Use this, for example, together with [QuestProgressUnlocker]
## to block off sections of Fray's End with water or void until the player has
## completed certain quests. (Depending on the level design, a door may be more
## appropriate.)
## [br][br]
## This script may be attached to a [TileMapLayer] directly; instantiated as a
## child of a [TileMapLayer]; or instantiated elsewhere in the tree, in which
## case [member target] must be set.

## The [TileMapLayer] to be toggled. If this script is attached directly to a
## [TileMapLayer], this property cannot be changed.
@export var target: TileMapLayer:
	set = _set_target


func _enter_tree() -> void:
	if not target:
		if (self as Node2D) is TileMapLayer:
			target = (self as Node2D) as TileMapLayer
		elif get_parent() is TileMapLayer:
			target = get_parent()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"target":
			if target == self:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _set_target(value: TileMapLayer) -> void:
	target = value
	notify_property_list_changed()
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not target and (self as Node2D) is not TileMapLayer:
		warnings.push_back("Target is not set")
	return warnings


func set_toggled(value: bool) -> void:
	target.enabled = not value
