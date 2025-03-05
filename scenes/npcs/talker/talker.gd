@tool
class_name Talker
extends NPC

const DEFAULT_DIALOGUE: DialogueResource = preload("res://scenes/npcs/talker/default.dialogue")

@export var npc_name: String
@export var dialogue: DialogueResource = DEFAULT_DIALOGUE
