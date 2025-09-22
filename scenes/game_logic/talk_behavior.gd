# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name TalkBehavior
extends Node
## Display a dialogue when interacted.
##
## It displays the [member dialogue] passing the parent node and the player as the extra game
## state.
## If [member title] is set, it will display the dialogue at that title.[br][br]
## When the dialogue ends, it finishes the interaction by calling [method
## InteractArea.end_interaction].
## If the parent is an NPC, it sets the [member InteractArea.action] to "Talk to NAME",
## where NAME is the [member NPC.npc_name].[br][br]
## Optionally, an awaitable function can be passed to [member before_dialogue] if
## something needs to happen before the [member dialogue] is displayed. This can be used,
## for example, to dynamically set the [member title] of the dialogue considering the
## game state at the moment the interaction happens.

@export var dialogue: DialogueResource = preload("uid://cc3paugq4mma4")
@export var title: String = ""
@export var interact_area: InteractArea:
	set = _set_interact_area

var before_dialogue: Callable


func _set_interact_area(new_interact_area: InteractArea) -> void:
	interact_area = new_interact_area
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not interact_area:
		warnings.append("Interact Area property must be set.")
	return warnings


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interact_area.interaction_started.connect(_on_interaction_started)

	var npc := get_parent() as NPC
	if npc and npc.npc_name:
		interact_area.action = "Talk to %s" % npc.npc_name


func _on_interaction_started(player: Player, _from_right: bool) -> void:
	if before_dialogue:
		await before_dialogue.call()
	DialogueManager.show_dialogue_balloon(dialogue, title, [get_parent(), player])
	await DialogueManager.dialogue_ended
	interact_area.end_interaction()
