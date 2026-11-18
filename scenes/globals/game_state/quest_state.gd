# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name QuestState
extends Resource

## The quest being played.
## [br][br]
## It's not saved to disk, see [method _validate_property]. The [member quest_path]
## is saved instead, so that moving or deleting a quest.tres file in the
## project doesn't break loading a saved game.
@export var quest: Quest

## Generic game state facts about the current quest. Outside quests, use [member GlobalState.facts]
## instead.
@export var facts: Dictionary[String, Variant]

## Resource path of [member quest], which is what is actually saved to disk.
## Use [member quest] instead.
## [br][br]
## When the saved game is loaded, this setter loads [member quest] from the path.
## This script is not a tool script, so the setter doesn't run in the editor.
@export_storage var quest_path: String:
	get():
		return quest.resource_path if quest else ""
	set(new_value):
		if ResourceLoader.exists(new_value):
			quest = ResourceLoader.load(new_value)
		else:
			if new_value != "":
				push_warning("Quest path in saved game does not exist: %s" % new_value)
			quest = null

## Path to the starting scene of the current challenge, which is where the
## player returns to if they run out of lives. If not set, defaults to
## [member quest]'s [Quest.first_scene].
@export var challenge_start_scene: String:
	get = get_challenge_start_scene, set = set_challenge_start_scene

## Player state within [member quest]. If the quest is a [LoreQuest],
## this will be initialised as a copy of [member
## GlobalState.player], and propagated back to [GlobalState] if the quest is
## completed. For StoryQuests, this is a fresh state at the start of the quest
## and is discarded at the end.
@export var player: PlayerState = PlayerState.new()

## The path to the scene to return to if the quest is abandoned.
@export var abandon_scene_path: String

## [SpawnPoint] node within [member abandon_scene_path] to return to if the
## quest is abandoned.
@export var abandon_spawn_point: NodePath

## Inventory of collected threads.
@export var inventory := InventoryState.new()


func _init(q: Quest = null, p: PlayerState = null) -> void:
	quest = q
	player = p


func _validate_property(property: Dictionary) -> void:
	match property.name:
		# Keep quest exported, so it shows in the inspector, but don't save it.
		# Saving it would add an ext_resource for the quest.tres to the saved game.
		# An alternative to this would be a complex @export_custom.
		"quest":
			property.usage &= ~PROPERTY_USAGE_STORAGE


func get_challenge_start_scene() -> String:
	assert(quest != null)

	if challenge_start_scene:
		return challenge_start_scene

	return quest.first_scene


func set_challenge_start_scene(value: String) -> void:
	challenge_start_scene = ResourceUID.ensure_path(value)
	emit_changed()
