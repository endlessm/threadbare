# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EternalLoom
extends Node2D

const ETERNAL_LOOM_INTERACTION: DialogueResource = preload("uid://yafw7bf362gh")

## Scenes that are the first of three Sokoban puzzles. A random one will be used
## each time the player successfully interacts with the Loom.
const SOKOBANS := [
	"uid://b8mywvmgsxqb",
	"uid://11cdlcqge3fu",
	"uid://b64uft76tbblp",
]

var elders: Array[Elder]

var _have_threads := is_item_offering_possible()

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior
@onready var loom_offering_animation_player: AnimationPlayer = %LoomOfferingAnimationPlayer


func _ready() -> void:
	talk_behavior.dialogue = ETERNAL_LOOM_INTERACTION
	talk_behavior.title = "have_threads" if _have_threads else "no_threads"
	interact_area.interaction_ended.connect(self._on_interaction_ended)

	if GameState.incorporating_threads:
		if Transitions.is_running():
			await Transitions.finished

		var elder := _find_elder(GameState.current_quest)
		await elder.congratulate_player()

		GameState.set_incorporating_threads(false)
		GameState.mark_quest_completed()


func _find_elder(quest: Quest) -> Elder:
	for elder in elders:
		if quest.resource_path.begins_with(elder.quest_directory):
			return elder

	return null


func _on_interaction_ended() -> void:
	if _have_threads:
		# Hide interact label during scene transition
		interact_area.disabled = true

		GameState.set_incorporating_threads(true)
		SceneSwitcher.change_to_file_with_transition(SOKOBANS.pick_random())


func on_offering_succeeded() -> void:
	loom_offering_animation_player.play(&"loom_offering")
	await loom_offering_animation_player.animation_finished
	GameState.clear_inventory()


func is_item_offering_possible() -> bool:
	return GameState.items_collected().size() >= InventoryItem.ItemType.size()
