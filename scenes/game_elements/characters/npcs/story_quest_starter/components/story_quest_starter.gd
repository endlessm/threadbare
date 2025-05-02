# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name StoryQuestStarter
extends Talker

const STORY_QUEST_STARTER_DIALOGUE: DialogueResource = preload("./story_quest_starter.dialogue")

## The first scene of a quest that this NPC offers to the player when they interact with them.
@export var quest_scene: PackedScene

## A reference to the loom, so that this Elder can determine whether you have
## the items you need to operate it.
@export var eternal_loom: EternalLoom

var book_sound = preload("res://assets/third_party/sounds/BookPage.ogg")
## Whether to enter [member quest_scene] when the current dialogue ends
var _enter_quest_on_dialogue_ended: bool = false

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	super._ready()
	animated_sprite.connect("frame_changed", _on_frame_changed)


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


func _on_frame_changed() -> void:
	if animated_sprite.frame == 2:
		var sound_player = AudioStreamPlayer2D.new()
		sound_player.stream = book_sound
		sound_player.max_distance = 500
		sound_player.pitch_scale = 2
		add_child(sound_player)
		sound_player.play()
