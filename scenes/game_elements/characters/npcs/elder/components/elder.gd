# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Elder
extends Talker

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

## Directory of quests that this NPC offers to the player during interactions.
@export_dir var quest_directory: String

## A reference to the loom, so that this Elder can determine whether you have
## the items you need to operate it.
@export var eternal_loom: EternalLoom:
	set(new_value):
		eternal_loom = new_value
		update_configuration_warnings()

## Sound that plays for each step during the walk animation.
## It plays once each time the idle animation gets to the second frame.
@export var idle_sound_stream: AudioStream = preload("uid://dxbxx6x5h7d8p"):
	set = _set_idle_sound_stream

## The quest chosen by the player from the storybook
var chosen_quest: Quest

var _dialogue_balloon: CanvasLayer
var _storybook: Storybook

@onready var _book_sound: AudioStreamPlayer2D = %BookSound
@onready var _storybook_layer: CanvasLayer = %StorybookLayer


func _ready() -> void:
	super._ready()
	animated_sprite_2d.connect("frame_changed", _on_frame_changed)

	if quest_directory:
		_storybook = STORYBOOK_SCENE.instantiate()
		_storybook.quest_directory = quest_directory


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array[String] = []

	if not quest_directory:
		warnings.append("Quest Directory property should be set")

	if not eternal_loom:
		warnings.append("Eternal Loom property must be set")

	return warnings


# Override this talker method so we can vary the dialogue title based on
# whether the loom offering is possible.
func _on_interaction_started(player: Player, _from_right: bool) -> void:
	var title: String = ""
	if eternal_loom and eternal_loom.is_item_offering_possible():
		title = "go_to_loom"
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	_dialogue_balloon = DialogueManager.show_dialogue_balloon(dialogue, title, [self, player])


## Show a storybook to the player, and wait for them to select a story or close the book.
func show_storybook() -> void:
	if not _storybook:
		return

	# GDM will hide the balloon after a short pause if the awaitable hasn't resolved, but we want it
	# to be replaced with the storybook immediately.
	if _dialogue_balloon:
		_dialogue_balloon.balloon.hide()

	_storybook_layer.add_child(_storybook)
	_storybook.reset_focus()
	chosen_quest = await _storybook.selected
	_storybook_layer.remove_child(_storybook)


func _on_dialogue_ended(dialogue_resource: DialogueResource) -> void:
	super(dialogue_resource)

	if chosen_quest:
		%InteractArea.disabled = true
		GameState.start_quest(chosen_quest)
		SceneSwitcher.change_to_file_with_transition(
			chosen_quest.first_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)
		chosen_quest = null


func _on_frame_changed() -> void:
	if animated_sprite_2d.frame == 2:
		_book_sound.play()


func _set_idle_sound_stream(new_value: AudioStream) -> void:
	idle_sound_stream = new_value
	if not is_node_ready():
		await ready
	_book_sound.stream = idle_sound_stream
