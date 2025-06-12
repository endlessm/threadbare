# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool

## Make the character start a dialogue when interacted.
class_name CanTalk
extends Node2D

@export var dialogue: DialogueResource = preload("uid://cc3paugq4mma4")
@export var interact_area: InteractAreaNew:
	set = _set_interact_area

# TODO: Add configuration warning to the node if the parent is not a Character.
@onready var character: Character = get_parent()


func _ready() -> void:
	print("%s: I can talk" % character.name)
	_set_interact_area(interact_area)


func _set_interact_area(new_interact_area: InteractAreaNew) -> void:
	if interact_area and interact_area.interaction_started.is_connected(_on_interaction_started):
		interact_area.interaction_started.disconnect(_on_interaction_started)
	interact_area = new_interact_area
	update_configuration_warnings()
	if not is_node_ready():
		return
	if interact_area:
		interact_area.interaction_started.connect(_on_interaction_started)


func _get_configuration_warnings() -> PackedStringArray:
	if not interact_area:
		return ["An interact area must be set."]
	return []


func _on_interaction_started(player: Character, _from_right: bool) -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	var extra_state := {"npc_name": character.character_name}
	var player_state := {"player_name": player.character_name}
	DialogueManager.show_dialogue_balloon(dialogue, "", [extra_state, player_state])


func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	interact_area.interaction_ended.emit()
