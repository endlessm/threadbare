# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EternalLoom
extends Node2D

signal retelling_started
signal retelling_finished
signal give_retelling_upgrade(type: InventoryItem.ItemType)

## Paths to world-rewoven cutscenes that will be shown.
## They must switch back to Fray's End after playing an animation.
@export var cutscene_paths: Array[String] = [
	"res://scenes/game_elements/fx/world_rewoven/components/world_rewoven_cutscene_1.tscn",
	"res://scenes/game_elements/fx/world_rewoven/components/world_rewoven_cutscene_2.tscn",
]

var elders: Array[Elder]

@onready var interact_area: InteractArea = %InteractArea
@onready var talk_behavior: TalkBehavior = %TalkBehavior
@onready var loom_offering_animation_player: AnimationPlayer = %LoomOfferingAnimationPlayer


func _find_elder(quest: Quest) -> Elder:
	for elder in elders:
		if quest.resource_path.begins_with(elder.quest_directory):
			return elder

	# No matching elder. This was probably a quest launched from Dev Island.
	return elders[-1]


## Called from the dialogue when retelling is possible.
func start_retelling() -> void:
	retelling_started.emit()


## The [member RetellingManager] calls this to display the retelling dialogue.
func show_retelling_dialogue() -> void:
	DialogueManager.show_dialogue_balloon(GameState.quest.quest.retelling, "", [self])
	await DialogueManager.dialogue_ended
	retelling_finished.emit()


func _has_magical_thread_of_type(type: InventoryItem.ItemType) -> bool:
	for item: InventoryItem in GameState.quest.inventory.items:
		if item.type == type:
			return true
	return false


func has_memory() -> bool:
	return _has_magical_thread_of_type(InventoryItem.ItemType.MEMORY)


func has_imagination() -> bool:
	return _has_magical_thread_of_type(InventoryItem.ItemType.IMAGINATION)


func has_spirit() -> bool:
	return _has_magical_thread_of_type(InventoryItem.ItemType.SPIRIT)


func _give_upgrade(type: InventoryItem.ItemType) -> void:
	var has_it := _has_magical_thread_of_type(type)
	if not has_it:
		push_warning("Trying to give an upgrade for missing item type", type)
		return
	give_retelling_upgrade.emit(type)


func give_memory_upgrade() -> void:
	_give_upgrade(InventoryItem.ItemType.MEMORY)


func give_imagination_upgrade() -> void:
	_give_upgrade(InventoryItem.ItemType.IMAGINATION)


func give_spirit_upgrade() -> void:
	_give_upgrade(InventoryItem.ItemType.SPIRIT)


func on_offering_succeeded() -> void:
	var cutscene_path: String = cutscene_paths.pick_random()
	var load_error: Error = ResourceLoader.load_threaded_request(cutscene_path)

	GameState.global.facts.rewoven_cutscenes = [cutscene_path]

	if load_error != OK:
		push_error("Failed to start loading %s: %s" % [cutscene_path, error_string(load_error)])

	loom_offering_animation_player.play(&"loom_offering")
	await loom_offering_animation_player.animation_finished
	GameState.quest.inventory.clear_inventory()

	if load_error != OK:
		on_rewoven_finished()
		return

	var cutscene_packed: PackedScene = ResourceLoader.load_threaded_get(cutscene_path)
	SceneSwitcher.change_to_packed_with_transition(
		cutscene_packed, "", Transitions.Effect.FADE, Transitions.Effect.FADE
	)


func on_rewoven_finished() -> void:
	var elder: Elder = _find_elder(GameState.quest.quest)
	if elder:
		await elder.congratulate_player()

	GameState.mark_quest_completed()
	GameState.save()


func has_retelling() -> bool:
	return GameState.quest and GameState.quest.quest and GameState.quest.quest.retelling


func is_item_offering_possible() -> bool:
	if not GameState.quest:
		return false

	if GameState.quest.quest.threads_to_collect <= 0:
		return false

	return GameState.quest.inventory.items.size() >= GameState.quest.quest.threads_to_collect
