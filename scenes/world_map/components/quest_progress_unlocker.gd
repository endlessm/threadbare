# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name QuestProgressUnlocker
extends Node
## Toggle game elements when certain quests have been completed
##
## This can be used to unlock a door, or paired with [ToggleableTileMapLayer] to
## disable some tiles, once the player has completed certain quests, opening
## a new region of the map.

## Emitted when the scene starts, indicating the initial state of this unlocker.
signal initialized(satisfied: bool)

## Emitted when all quests in [member required_quests] have become completed.
## [param satisfied] matches the current value of [member is_satisfied].
## (In development, it is also possible for a quest to be un-completed and
## therefore for an unlocker to become unsatisfied.)
signal toggled(satisfied: bool)

## Nodes to toggle on scene start & when the completion state changes.
## (You can also connect to [signal toggled] and [signal initialized] directly.)
@export var targets: Array[Toggleable]

## Quests which must be completed to unlock [member targets].
@export var required_quests: Array[Quest]:
	set = _set_required_quests


func _set_required_quests(new_value: Array[Quest]) -> void:
	required_quests = new_value
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not required_quests:
		warnings.append("At least one required quest should be set")
	return warnings


func _ready() -> void:
	_connect_targets()

	GameState.completed_quests_changed.connect(_on_completed_quests_changed)

	# To ensure the targets are ready, we do a "call_deferred"
	_initialize_toggle_state.call_deferred()


func _connect_targets() -> void:
	for target: Toggleable in targets:
		initialized.connect(target.initialize_with_value)
		toggled.connect(target.set_toggled)


func _initialize_toggle_state() -> void:
	initialized.emit(is_satisfied())


func _on_completed_quests_changed() -> void:
	toggled.emit(is_satisfied())


## Returns whether all quests in [member required_quests] have been completed.
func is_satisfied() -> bool:
	for quest: Quest in required_quests:
		# TODO: would be better if completed_quests held the Quest resources...
		if quest.resource_path not in GameState.completed_quests:
			return false

	return true
