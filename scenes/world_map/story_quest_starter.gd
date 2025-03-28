@tool
class_name StoryQuestStarter
extends Talker

const STORY_QUEST_STARTER_DIALOGUE: DialogueResource = preload(
	"res://scenes/world_map/story_quest_starter.dialogue"
)

## The first scene of a quest that this NPC offers to the player when they interact with them.
@export var quest_scene: PackedScene

## Dialogue line describing the quest; used by the default story_quest_starter dialogue
@export var quest_description: String

## Whether to enter [member quest_scene] when the current dialogue ends
var _enter_quest_on_dialogue_ended: bool = false


func _init() -> void:
	# GDScript does not allow subclasses to override the default value of properties on the parent
	# class. Fake this here – the default talker dialogue is certainly not wanted by instances of
	# this class.
	if dialogue == Talker.DEFAULT_DIALOGUE:
		dialogue = STORY_QUEST_STARTER_DIALOGUE


func _get_configuration_warnings() -> PackedStringArray:
	if quest_scene:
		return []

	return ["Quest Scene property should be set"]


## At the end of the current interaction, enter [member quest_scene]. This is intended to be called
## from dialogue.
func enter_quest() -> void:
	_enter_quest_on_dialogue_ended = true


func _on_dialogue_ended(dialogue_resource: DialogueResource) -> void:
	await super(dialogue_resource)

	if _enter_quest_on_dialogue_ended:
		SceneSwitcher.change_to_packed(quest_scene)
		_enter_quest_on_dialogue_ended = false
