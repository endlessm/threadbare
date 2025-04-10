# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Talker
extends NPC

const DEFAULT_DIALOGUE: DialogueResource = preload(
	"res://scenes/game_elements/characters/npcs/talker/components/default.dialogue"
)

@export var npc_name: String
@export var dialogue: DialogueResource = DEFAULT_DIALOGUE

var _previous_look_at_side: NPC.LookAtSide = NPC.LookAtSide.LEFT

@onready var interact_area: InteractArea = %InteractArea


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	interact_area.interaction_started.connect(_on_interaction_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interaction_started(from_right: bool) -> void:
	_previous_look_at_side = look_at_side
	if look_at_side != NPC.LookAtSide.FRONT:
		look_at_side = NPC.LookAtSide.RIGHT if from_right else NPC.LookAtSide.LEFT
	DialogueManager.show_dialogue_balloon(dialogue, "", [self])


func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	look_at_side = _previous_look_at_side
	# This little wait is needed to avoid triggering another dialogue:
	await get_tree().create_timer(0.3).timeout
	interact_area.interaction_ended.emit()
