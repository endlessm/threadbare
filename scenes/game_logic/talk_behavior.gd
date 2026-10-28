# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name TalkBehavior
extends Node
## Display a dialogue when interacted.
##
## It displays the [member dialogue] passing the parent node and the player as the extra game
## state.
## If [member cue] is set, it will display the dialogue at that cue.[br][br]
## When the dialogue ends, it finishes the interaction by calling [method
## InteractArea.end_interaction].
## If the parent is an NPC, it sets the [member InteractArea.action_text] to "Talk to NAME",
## where NAME is the [member NPC.npc_name].[br][br]

## The dialogue to display.
@export var dialogue: DialogueResource = preload("uid://cc3paugq4mma4")

## Cue within [member dialogue] to play. If empty, start at the top of [member dialogue].
@export var cue: String = "":
	set = _set_cue

## The area that the player-character should interact to display the dialogue.
## The interaction will last until the dialogue ends.
@export var interact_area: InteractArea:
	set = _set_interact_area

## Other nodes in the scene tree to make available in [member dialogue], in addition to
## properties defined on the parent node and on the [Player] scene.
## Each node in this list can be accessed by its [member Node.name].
## Having multiple nodes in this list with the same name is not advised.
@export var extra_context: Array[Node]


#region Setters

func _set_cue(new_value: String) -> void:
	cue = new_value
	update_configuration_warnings()


func _set_interact_area(new_interact_area: InteractArea) -> void:
	interact_area = new_interact_area
	update_configuration_warnings()

#endregion


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not interact_area:
		warnings.append("Interact Area property must be set.")
	if dialogue and cue and cue not in dialogue.get_cues():
		warnings.append("Dialogue Cue '%s' does not exist" % cue)
	return warnings


func _set(property: StringName, value: Variant) -> bool:
	# Scenes saved before the rename store the cue as title. Map it to cue, which
	# is the name the editor saves from now on.
	# Can be removed when we don't expect to have to rewrite any new quests being merged.
	if property == &"title":
		cue = value
		return true
	return false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interact_area.interaction_started.connect(_on_interaction_started)

	var npc := get_parent() as NPC
	if npc and npc.npc_name:
		interact_area.action_text = tr("Talk to %s") % npc.npc_name


func _on_interaction_started(player: Player, _from_right: bool) -> void:
	var extra: Dictionary[String, Node]
	for node: Node in extra_context:
		extra[node.name] = node
	DialogueManager.show_dialogue_balloon(dialogue, cue, [get_parent(), player, extra])
	await DialogueManager.dialogue_ended
	interact_area.end_interaction()
