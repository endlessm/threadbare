# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Elder
extends CharacterBody2D

const STORYBOOK_SCENE := preload("uid://bhm7fdjvppt8b")

## Directory of quests that this Elder offers to the player during interactions.
## This directory should have 1 or more subdirectories, each of which
## have a [code]quest.tres[/code] file within.
@export_dir var quest_directory: String:
	set = _set_quest_directory

## A reference to the loom, so that this Elder can determine whether you have
## the items you need to operate it.
@export var eternal_loom: EternalLoom:
	set(new_value):
		eternal_loom = new_value
		update_configuration_warnings()

## The quest chosen by the player from the storybook
var chosen_quest: Quest

var _quests: Array[Quest]

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

	interact_area.interaction_ended.connect(_on_interaction_ended)
	animated_sprite_2d.connect("frame_changed", _on_frame_changed)

	GameState.global.item_collected.connect(_update_dialogue_title)
	GameState.global.item_consumed.connect(_update_dialogue_title)
	_update_dialogue_title()


func _set_quest_directory(new_value: String) -> void:
	quest_directory = new_value
	if Engine.is_editor_hint():
		return
	_quests = Quest.enumerate(quest_directory)
	if is_node_ready():
		_update_dialogue_title()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array[String] = []

	if not quest_directory:
		warnings.append("Quest Directory property should be set")

	if not eternal_loom:
		warnings.append("Eternal Loom property must be set")

	return warnings


## Show a storybook to the player, and wait for them to select a story or close the book.
func show_storybook() -> void:
	var storybook := STORYBOOK_SCENE.instantiate()
	storybook.quests = _quests

	# GDM will hide the balloon after a short pause if the awaitable hasn't resolved, but we want it
	# to be replaced with the storybook immediately.
	if talk_behavior.dialogue_balloon:
		# Confusingly the DialogueBalloon node (root of our balloon.tscn) has a balloon property;
		# it is the latter which gets hidden and shown.
		talk_behavior.dialogue_balloon.balloon.hide()

	_storybook_layer.add_child(storybook)
	chosen_quest = await storybook.selected
	_storybook_layer.remove_child(storybook)
	storybook.queue_free()


func congratulate_player() -> void:
	DialogueManager.show_dialogue_balloon(talk_behavior.dialogue, "threads_incorporated", [self])
	await DialogueManager.dialogue_ended


func _update_dialogue_title(_item: InventoryItem = null) -> void:
	if eternal_loom and eternal_loom.is_item_offering_possible():
		talk_behavior.title = "go_to_loom"
	elif not _quests:
		talk_behavior.title = "no_quests"
	else:
		talk_behavior.title = ""


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
