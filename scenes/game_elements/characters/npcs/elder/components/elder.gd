# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Elder
extends CharacterBody2D

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

## Directory of quests that this Elder offers to the player during interactions.
@export_dir var quest_directory: String

## A reference to the loom, so that this Elder can determine whether you have
## the items you need to operate it.
@export var eternal_loom: EternalLoom:
	set(new_value):
		eternal_loom = new_value
		update_configuration_warnings()

## The quest chosen by the player from the storybook
var chosen_quest: Quest

var _dialogue_balloon: CanvasLayer
var _storybook: Storybook

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior
@onready var _book_sound: AudioStreamPlayer2D = %BookSound
@onready var _storybook_layer: CanvasLayer = %StorybookLayer


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if self not in eternal_loom.elders:
		eternal_loom.elders.append(self)

	talk_behavior.before_dialogue = _before_dialogue
	interact_area.interaction_ended.connect(_on_interaction_ended)
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


func congratulate_player() -> void:
	DialogueManager.show_dialogue_balloon(talk_behavior.dialogue, "threads_incorporated", [self])
	await DialogueManager.dialogue_ended


func _before_dialogue() -> void:
	if eternal_loom and eternal_loom.is_item_offering_possible():
		talk_behavior.title = "go_to_loom"


func _on_interaction_ended() -> void:
	if chosen_quest:
		interact_area.disabled = true
		GameState.start_quest(chosen_quest)
		SceneSwitcher.change_to_file_with_transition(
			chosen_quest.first_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
		)
		chosen_quest = null


func _on_frame_changed() -> void:
	if animated_sprite_2d.frame == 2:
		_book_sound.play()
