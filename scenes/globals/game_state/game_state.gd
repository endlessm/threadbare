# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

## Emitted when [member player] changes to a new [PlayerState] object, due to a
## quest starting or ending. This is used by the [Player] scene to rebind to
## signals like [signal PlayerState.abilities_changed].
signal player_changed(old: PlayerState, new: PlayerState)

const SAVE_PATH := "user://saved_game.tres"

## The player abilities to have from the beginning
## when not running the game from the main scene.
const DEBUG_PLAYER_ABILITIES := [
	Enums.PlayerAbilities.ABILITY_A,
	Enums.PlayerAbilities.ABILITY_B,
]

## Scenes to skip from saving.
const TRANSIENT_SCENES := [
	"res://scenes/menus/title/title_screen.tscn",
]

## The progress is persisted only if the game is run normally from the main scene.
## Otherwise, it means we are playing a specific scene: the current scene from the editor or
## with a direct URL hash to a scene in the web build. In the latter cases, this variable is false.
var persist_progress: bool

## Game-wide state.
var global: GlobalState:
	get():
		return _saved_game.global if _saved_game else null
	set(new_value):
		push_error("Do not set GameState.global")

## State concerning the current quest, or [code]null[/code] if there is no current quest.
var quest: QuestState:
	get():
		return _saved_game.quest if _saved_game else null
	set(new_value):
		var old_player_state := player
		_saved_game.quest = new_value
		player_changed.emit(old_player_state, player)

## State concerning the current scene, or [code]null[/code] if there is no current scene
var scene: PerSceneState:
	get():
		return _saved_game.scene if _saved_game else null
	set(new_value):
		_saved_game.scene = new_value

## If the player is on a quest, the [member QuestState.player] of [member
## quest]. Otherwise, the [member GlobalState.player] of [member global]. Use
## this rather than referring directly to those.
var player: PlayerState:
	get():
		return quest.player if quest else global.player
	set(new_value):
		push_error("Do not set GameState.player")

var _saved_game: SavedGame


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if ResourceLoader.exists(SAVE_PATH):
		_saved_game = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	if not _saved_game:
		_saved_game = SavedGame.new()

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
		# Grant all debug player abilities:
		for ability: Enums.PlayerAbilities in DEBUG_PLAYER_ABILITIES:
			player.set_ability(ability, true)
		return


## Sets [member quest], setting up a new [PlayerState] if necessary.
## Note that this does not actually switch to the first scene of [param
## new_quest].
func start_quest(new_quest: Quest) -> void:
	var quest_player_state: PlayerState
	if new_quest is LoreQuest:
		# Duplicate the current global player state. If the quest is completed,
		# it will be copied back; if abandoned, it will be discarded.
		quest_player_state = global.player.duplicate()
		quest_player_state.reset_lives()
	else:
		# Use a fresh player state for StoryQuests
		quest_player_state = PlayerState.new()

	quest = QuestState.new(new_quest, quest_player_state)


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
			var q := ResourceLoader.load(quest_path) as Quest
			quest = QuestState.new(q, PlayerState.new())
			quest.challenge_start_scene = scene_path
			prints("Guessed quest", quest.resource_path, "from scene", scene_path)
			return

		dir_path = dir_path.get_base_dir()


## Set the scene path and [member current_spawn_point], and save the game.
func set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	if scene_path in TRANSIENT_SCENES:
		return

	if not scene or scene.path != scene_path:
		scene = PerSceneState.new(scene_path)

	scene.spawn_point = spawn_point
	save()


## Record [member quest] as completed, copying its player state to the global
## state if it was a LoreQuest, and clear [member quest].
func mark_quest_completed() -> void:
	assert(quest)

	if quest.quest is LoreQuest:
		# Copy quest abilities to game abilities.
		global.player = quest.player

	global.set_quest_completed_state(quest.quest, true)
	quest = null


## Abandon the current [member quest] without marking it as completed.
func abandon_quest() -> void:
	quest = null


## Clear the persisted state.
func clear() -> void:
	_saved_game = SavedGame.new()


## Check if there is persisted state.
func can_restore() -> bool:
	return scene != null


## Save the game state (if [persist_progress] is [code]true[/code])
func save() -> void:
	if not persist_progress:
		return

	var e := ResourceSaver.save(_saved_game, SAVE_PATH)
	if e != OK:
		push_error("Failed to save state to %s: %d %s" % [SAVE_PATH, e, error_string(e)])
