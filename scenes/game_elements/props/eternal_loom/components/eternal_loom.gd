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

@onready var interact_area: InteractArea = %InteractArea
@onready var loom_offering_animation_player: AnimationPlayer = %LoomOfferingAnimationPlayer


func _ready() -> void:
	interact_area.interaction_started.connect(self._on_interacted)

	if GameState.incorporating_threads:
		if Transitions.is_running():
			await Transitions.finished

		DialogueManager.show_dialogue_balloon(
			ETERNAL_LOOM_INTERACTION, "threads_incorporated", [self]
		)
		await DialogueManager.dialogue_ended
		GameState.set_incorporating_threads(false)


func _on_interacted(player: Player, _from_right: bool) -> void:
	var have_threads := is_item_offering_possible()

	var title := "have_threads" if have_threads else "no_threads"
	DialogueManager.show_dialogue_balloon(ETERNAL_LOOM_INTERACTION, title, [self, player])
	await DialogueManager.dialogue_ended

	interact_area.end_interaction()

	if have_threads:
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
