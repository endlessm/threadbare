# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Elder
extends Talker

## The first scene of a quest that this NPC offers to the player when they interact with them.
@export var quest_scene: PackedScene

## A reference to the loom, so that this Elder can determine whether you have
## the items you need to operate it.
@export var eternal_loom: EternalLoom

## Whether to enter [member quest_scene] when the current dialogue ends
var _enter_quest_on_dialogue_ended: bool = false


func _get_configuration_warnings() -> PackedStringArray:
	if quest_scene:
		return []

	return ["Quest Scene property should be set"]


# Override this talker method so we can vary the dialogue title based on
# whether the loom offering is possible.
func _on_interaction_started(player: Player, _from_right: bool) -> void:
	var title: String = ""
	if eternal_loom and eternal_loom.is_item_offering_possible():
		title = "go_to_loom"
	DialogueManager.show_dialogue_balloon(dialogue, title, [self, player])


## At the end of the current interaction, enter [member quest_scene]. This is intended to be called
## from dialogue.
func enter_quest() -> void:
	_enter_quest_on_dialogue_ended = true


func _on_dialogue_ended(dialogue_resource: DialogueResource) -> void:
	await super(dialogue_resource)

	if _enter_quest_on_dialogue_ended:
		%InteractArea.disabled = true
		GameState.start_quest()
		SceneSwitcher.change_to_packed_with_transition(
			quest_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)
		_enter_quest_on_dialogue_ended = false
