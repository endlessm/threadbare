# gdlint: disable=max-public-methods
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

## Emitted when a new item is collected, even if it wasn't added to the
## inventory due to it being already there.
signal item_collected(item: InventoryItem)

## Emitted when a item is consumed, causing it to be removed from the
## [member inventory].
signal item_consumed(item: InventoryItem)

## Emitted whenever the items in the inventory change, either by collecting
## or consuming an item.
signal collected_items_changed(updated_items: Array[InventoryItem])

## Emitted when the player's lives change.
signal lives_changed(new_lives: int)

## Emitted when it becomes too dark that artificial lights can turn on, or
## when darkness goes away so artificial lights should turn off.
signal lights_changed(lights_on: bool, immediate: bool)

## Emitted when a quest is added or removed from [member completed_quests].
signal completed_quests_changed

## Emitted when lore or StoryQuest player abilities change.
signal abilities_changed

const GAME_STATE_PATH := "user://game_state.cfg"
const INVENTORY_SECTION := "inventory"
const INVENTORY_ITEMS_KEY := "items_collected"
const QUEST_CHALLENGE_START_KEY := "challenge_start_scene"
const QUEST_PLAYER_ABILITIES_KEY := "storyquest_player_abilities"
const QUEST_ABANDON_SCENE_KEY := "abandon_scene"
const QUEST_ABANDON_SPAWNPOINT_KEY := "abandon_spawn_point"
const GLOBAL_SECTION := "global"
const GLOBAL_INCORPORATING_THREADS_KEY := "incorporating_threads"
const COMPLETED_QUESTS_KEY := "completed_quests"
const LORE_PLAYER_ABILITIES_KEY := "lore_player_abilities"
const QUEST_PATH_KEY := "quest_path"
const CURRENTSCENE_KEY := "current_scene"
const SPAWNPOINT_KEY := "current_spawn_point"
const LIVES_KEY := "current_lives"
const MAX_LIVES := 2 ** 53
const DEBUG_LIVES := false

## Scenes to skip from saving.
const TRANSIENT_SCENES := [
	"res://scenes/menus/title/title_screen.tscn",
	"res://scenes/menus/intro/intro.tscn",
]

## Global inventory, used to track the items the player obtains and that
## can be added to the loom.
@export var inventory: Array[InventoryItem] = []
@export var current_spawn_point: NodePath

## Player abilities for the whole game.
## [br][br]
## These are flags that enable systems or mechanics for the player progression
## during the entire game.[br]
## When involved in a StoryQuest, [member storyquest_player_abilities] are used instead.
@export var lore_player_abilities: int = 0:
	set = _set_lore_player_abilities

## Player abilities for the current StoryQuest.
## [br][br]
## These are flags that enable systems or mechanics for the StoryQuest progression[br]
## When involved in a lore quest, [member lore_player_abilities] are used instead.
@export var storyquest_player_abilities: int = 0

## Current number of lives the player has.
var current_lives: int = MAX_LIVES

## Current state of artificial lights.
var lights_on: bool

## Set when the loom transports the player to a trio of Sokoban puzzles, so that
## when the player returns to Fray's End the loom can trigger a brief cutscene.
var incorporating_threads: bool = false

## Set when any introductory dialogue has been played for the current scene.
## Cleared when the scene changes.
var intro_dialogue_shown: bool = false

## The paths to the [Quest]s that the player has completed, in the order that they were completed.
var completed_quests: Array[String] = []

## The quest that the player is currently playing, or [code]null[/code] if they
## are not playing a quest. Update this with [method start_quest], [method
## mark_quest_completed] and [method abandon_quest].
var current_quest: Quest

var persist_progress: bool
var _state := ConfigFile.new()


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		# Treat the player abilities as bit flags.
		# The @export_flags would be ideal but it expects constant
		# strings, and we want to use the PlayerAbilities enum keys
		# as hint strings.
		# This also requires this script to be a @tool.
		"lore_player_abilities", "storyquest_player_abilities":
			property.hint = PROPERTY_HINT_FLAGS
			property.hint_string = ",".join(Enums.PlayerAbilities.keys())


func _ready() -> void:
	var current_scene := get_tree().current_scene
	var initial_scene_uid := (
		ResourceLoader.get_resource_uid(current_scene.scene_file_path) if current_scene else -1
	)
	var main_scene_uid := ResourceLoader.get_resource_uid(
		ProjectSettings.get_setting("application/run/main_scene")
	)
	persist_progress = initial_scene_uid == main_scene_uid
	if not persist_progress:
		if current_scene:
			guess_quest(current_scene.scene_file_path)
		return

	var err := _state.load(GAME_STATE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [GAME_STATE_PATH, err])

	if DEBUG_LIVES:
		prints("[LIVES DEBUG] GameState initialized with", current_lives, "lives")


## Set the [member incorporating_threads] flag.
func set_incorporating_threads(new_incorporating_threads: bool) -> void:
	incorporating_threads = new_incorporating_threads
	_state.set_value(GLOBAL_SECTION, GLOBAL_INCORPORATING_THREADS_KEY, incorporating_threads)
	_save()


## Set [member current_quest] and clear the [member inventory].
## Also resets lives to maximum when starting a quest.
func start_quest(
	quest: Quest,
	abandon_scene: String = "",
	abandon_spawn_point: NodePath = ^"",
) -> Dictionary:
	_do_clear_inventory()
	_update_inventory_state()
	current_quest = quest
	_state.set_value(GLOBAL_SECTION, QUEST_PATH_KEY, quest.resource_path)

	_state.set_value(quest.resource_path, QUEST_ABANDON_SCENE_KEY, abandon_scene)
	_state.set_value(quest.resource_path, QUEST_ABANDON_SPAWNPOINT_KEY, abandon_spawn_point)

	if not current_quest.is_lore_quest:
		storyquest_player_abilities = 0
		# _state.set_value(QUEST_SECTION, QUEST_PLAYER_ABILITIES_KEY, storyquest_player_abilities)

	# Reset lives when starting a new quest
	reset_lives()
	_save()

	var ret := {
		"scene_path": _state.get_value(quest.resource_path, CURRENTSCENE_KEY, quest.first_scene),
		"spawn_point": _state.get_value(quest.resource_path, SPAWNPOINT_KEY, ^""),
	}
	return ret


## Guess which quest the given scene is part of, and set [member current_quest]
## accordingly. If the quest cannot be determined, unset [member current_quest].
## [br][br]
## This is for use when jumping to a particular scene during development (e.g.
## with F6 in the editor, the URL hash in the browser, or in future if we add a
## level selector). During normal gameplay it should not be used.
func guess_quest(scene_path_or_uid: String) -> void:
	var scene_path := ResourceUID.ensure_path(scene_path_or_uid)
	var dir_path := scene_path.get_base_dir()
	while dir_path != "res://":
		var quest_path := dir_path.path_join("quest.tres")
		if ResourceLoader.exists(quest_path, "Resource"):
			current_quest = ResourceLoader.load(quest_path) as Quest
			prints("Guessed quest", current_quest.resource_path, "from scene", scene_path)
			return

		dir_path = dir_path.get_base_dir()

	current_quest = null


## Set the scene path and [member current_spawn_point].
func set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if scene_path in TRANSIENT_SCENES:
		return

	_do_set_scene(scene_path, spawn_point)
	_save()


## Set the current spawn point and save it.
func set_current_spawn_point(spawn_point: NodePath = ^"") -> void:
	current_spawn_point = spawn_point
	_state.set_value(GLOBAL_SECTION, SPAWNPOINT_KEY, current_spawn_point)
	if current_quest:
		_state.set_value(current_quest.resource_path, SPAWNPOINT_KEY, current_spawn_point)
	_save()


## Set the challenge start scene. This is the scene the player returns to
## when they run out of lives.
func set_challenge_start_scene(scene_path: String) -> void:
	if current_quest:
		_state.set_value(current_quest.resource_path, QUEST_CHALLENGE_START_KEY, scene_path)
		_save()


## Get the challenge start scene, or the first scene of the current quest
## if no challenge start has been set.
func get_challenge_start_scene() -> String:
	if not current_quest:
		return ""

	return _state.get_value(
		current_quest.resource_path, QUEST_CHALLENGE_START_KEY, current_quest.first_scene
	)


## Returns [code]true[/code] if the player is currently on a quest; i.e. if
## [member current_quest] is not [code]null[/code].
func is_on_quest() -> bool:
	return current_quest != null


## Clear all quest-related state from the config file.
func _clear_quest_state() -> void:
	if _state.has_section_key(GLOBAL_SECTION, QUEST_PATH_KEY):
		_state.erase_section_key(GLOBAL_SECTION, QUEST_PATH_KEY)


## If [member current_quest] is set, record this quest as having been completed,
## and unset it. Also resets lives to maximum.
func mark_quest_completed() -> void:
	if current_quest:
		_do_set_quest_completed_state(current_quest, true)
		current_quest = null
		_clear_quest_state()
		_save()


## Set the scene path and [member current_spawn_point] without triggering a save.
func _do_set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if get_scene_to_restore() != scene_path:
		intro_dialogue_shown = false

	current_spawn_point = spawn_point
	_state.set_value(GLOBAL_SECTION, CURRENTSCENE_KEY, scene_path)
	_state.set_value(GLOBAL_SECTION, SPAWNPOINT_KEY, current_spawn_point)
	if current_quest:
		_state.set_value(current_quest.resource_path, CURRENTSCENE_KEY, scene_path)
		_state.set_value(current_quest.resource_path, SPAWNPOINT_KEY, current_spawn_point)


## Add the [InventoryItem] to the [member inventory].
func add_collected_item(item: InventoryItem) -> void:
	inventory.append(item)
	item_collected.emit(item)
	collected_items_changed.emit(items_collected())
	_update_inventory_state()
	_save()


## If [member current_quest] is set, unset it, without recording the quest as
## having been completed. Also resets lives to maximum.
func abandon_quest() -> Dictionary:
	assert(current_quest)
	var ret := {
		"scene_path": _state.get_value(current_quest.resource_path, QUEST_ABANDON_SCENE_KEY, ""),
		"spawn_point":
		_state.get_value(current_quest.resource_path, QUEST_ABANDON_SPAWNPOINT_KEY, ^""),
	}
	set_incorporating_threads(false)
	_clear_quest_state()
	current_quest = null
	storyquest_player_abilities = 0
	clear_inventory()
	return ret


## Updates [member completed_quests] to include [param quest] if [param
## is_completed] is true, or remove [param quest] if [param is_completed] is
## false.
func set_quest_completed_state(quest: Quest, is_completed: bool) -> void:
	_do_set_quest_completed_state(quest, is_completed)
	_save()


func _do_set_quest_completed_state(quest: Quest, is_completed: bool) -> void:
	var quest_name := quest.resource_path
	if is_completed:
		if quest_name not in completed_quests:
			completed_quests.append(quest_name)
			completed_quests_changed.emit()
	else:
		while quest_name in completed_quests:
			completed_quests.erase(quest_name)
			completed_quests_changed.emit()


func _set_lore_player_abilities(new_lore_player_abilities: int) -> void:
	if lore_player_abilities == new_lore_player_abilities:
		return
	lore_player_abilities = new_lore_player_abilities
	abilities_changed.emit()


func _set_storyquest_player_abilities(new_storyquest_player_abilities: int) -> void:
	if storyquest_player_abilities == new_storyquest_player_abilities:
		return
	storyquest_player_abilities = new_storyquest_player_abilities
	abilities_changed.emit()


func _use_lore_abilities() -> bool:
	return current_quest == null or current_quest.is_lore_quest


## Enable or disable a player ability.
## [br][br]
## This will behave differently in the main "lore" game than in
## StoryQuests: the lore has player progression that last the whole game,
## while StoryQuests are narrative units and have their own player progression.
func set_ability(ability: Enums.PlayerAbilities, is_enabled: bool) -> void:
	if is_enabled:
		if not has_ability(ability):
			if _use_lore_abilities():
				lore_player_abilities |= ability
			else:
				storyquest_player_abilities |= ability
	else:
		if has_ability(ability):
			if _use_lore_abilities():
				lore_player_abilities &= ~ability
			else:
				storyquest_player_abilities &= ~ability
	if _use_lore_abilities():
		_state.set_value(GLOBAL_SECTION, LORE_PLAYER_ABILITIES_KEY, lore_player_abilities)
	else:
		pass
		# _state.set_value(QUEST_SECTION, QUEST_PLAYER_ABILITIES_KEY, storyquest_player_abilities)
	_save()


## Check if a player ability is enabled.
## [br][br]
## This will behave differently in the main "lore" game than in
## StoryQuests: the lore has player progression that last the whole game,
## while StoryQuests are narrative units and have their own player progression.
func has_ability(ability: Enums.PlayerAbilities) -> bool:
	if _use_lore_abilities():
		return lore_player_abilities & ability
	return storyquest_player_abilities & ability


## Remove all [InventoryItem] from the [member inventory].
func clear_inventory() -> void:
	_do_clear_inventory()
	_update_inventory_state()
	_save()


## Remove all [InventoryItem] from the [member inventory] without triggering a save.
func _do_clear_inventory() -> void:
	for item: InventoryItem in inventory.duplicate():
		inventory.erase(item)
		item_consumed.emit(item)
	collected_items_changed.emit(items_collected())


## Return all the items collected so far in the [member inventory].
func items_collected() -> Array[InventoryItem]:
	return inventory.duplicate()


func _update_inventory_state() -> void:
	_state.set_value(
		INVENTORY_SECTION,
		INVENTORY_ITEMS_KEY,
		inventory.map(func(i: InventoryItem) -> InventoryItem.ItemType: return i.type)
	)


## Decrement the player's lives by 1. Does not go below 0.
## Saves the new lives count.
func decrement_lives() -> void:
	current_lives = max(0, current_lives - 1)
	_state.set_value(GLOBAL_SECTION, LIVES_KEY, current_lives)
	_save()
	lives_changed.emit(current_lives)
	if DEBUG_LIVES:
		prints("[LIVES DEBUG] Lives decremented to:", current_lives)


## Reset the player's lives to maximum (3).
## Saves the new lives count.
func reset_lives() -> void:
	current_lives = MAX_LIVES
	_state.set_value(GLOBAL_SECTION, LIVES_KEY, current_lives)
	_save()
	lives_changed.emit(current_lives)
	if DEBUG_LIVES:
		prints("[LIVES DEBUG] Lives reset to:", current_lives)


## Add one life to the player, up to the maximum.
## This is for future "extra life" pickups.
func add_life() -> void:
	if current_lives < MAX_LIVES:
		current_lives += 1
		_state.set_value(GLOBAL_SECTION, LIVES_KEY, current_lives)
		_save()
		lives_changed.emit(current_lives)
		if DEBUG_LIVES:
			prints("[LIVES DEBUG] Life added. Lives now:", current_lives)


func change_lights(new_lights_on: bool, immediate: bool = false) -> void:
	lights_on = new_lights_on
	lights_changed.emit(lights_on, immediate)


## Clear the per-scene state.
func clear_per_scene_state() -> void:
	lights_on = false


## Clear the persisted state.
func clear() -> void:
	_state.clear()
	completed_quests = []
	lore_player_abilities = 0
	current_lives = MAX_LIVES
	if DEBUG_LIVES:
		prints("[LIVES DEBUG] State cleared. Lives reset to:", current_lives)
	_save()


## Check if there is persisted state.
func can_restore() -> bool:
	return get_scene_to_restore() != ""


## If there is a scene to restore, return it.
func get_scene_to_restore() -> String:
	return _state.get_value(GLOBAL_SECTION, CURRENTSCENE_KEY, "")


## Restore the persisted state.
func restore() -> Dictionary:
	inventory.clear()
	for item_type: InventoryItem.ItemType in _state.get_value(
		INVENTORY_SECTION, INVENTORY_ITEMS_KEY, []
	):
		var item := InventoryItem.with_type(item_type)
		inventory.append(item)

	if _state.has_section_key(GLOBAL_SECTION, QUEST_PATH_KEY):
		current_quest = load(_state.get_value(GLOBAL_SECTION, QUEST_PATH_KEY)) as Quest

	var scene_path: String = _state.get_value(GLOBAL_SECTION, CURRENTSCENE_KEY, "")
	current_spawn_point = _state.get_value(GLOBAL_SECTION, SPAWNPOINT_KEY, ^"")
	incorporating_threads = _state.get_value(
		GLOBAL_SECTION, GLOBAL_INCORPORATING_THREADS_KEY, false
	)
	completed_quests = _state.get_value(GLOBAL_SECTION, COMPLETED_QUESTS_KEY, [] as Array[String])

	lore_player_abilities = _state.get_value(GLOBAL_SECTION, LORE_PLAYER_ABILITIES_KEY, 0)
	# storyquest_player_abilities = _state.get_value(QUEST_SECTION, QUEST_PLAYER_ABILITIES_KEY, 0)

	# Restore lives from saved state, default to MAX_LIVES if not found
	current_lives = _state.get_value(GLOBAL_SECTION, LIVES_KEY, MAX_LIVES)
	if DEBUG_LIVES:
		prints("[LIVES DEBUG] State restored. Lives:", current_lives)

	return {"scene_path": scene_path, "spawn_point": current_spawn_point}


func _save() -> void:
	if not persist_progress:
		return
	_state.set_value(GLOBAL_SECTION, COMPLETED_QUESTS_KEY, completed_quests)
	var err := _state.save(GAME_STATE_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [GAME_STATE_PATH, err])
