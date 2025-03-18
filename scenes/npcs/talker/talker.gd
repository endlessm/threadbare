@tool
class_name Talker
extends NPC

const DEFAULT_DIALOGUE: DialogueResource = preload("res://scenes/npcs/talker/default.dialogue")

@export var npc_name: String
@export var dialogue: DialogueResource = DEFAULT_DIALOGUE

@onready var interact_area: InteractArea = %InteractArea


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	interact_area.interaction_started.connect(_on_interaction_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interaction_started() -> void:
	DialogueManager.show_dialogue_balloon(dialogue)


func _on_dialogue_ended(_dialogue_resource: DialogueResource) -> void:
	# This little wait is needed to avoid triggering another dialogue:
	await get_tree().create_timer(0.3).timeout
	interact_area.interaction_ended.emit()
