# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@onready var story_quest_progress: StoryQuestProgress = %StoryQuestProgress
@onready var zone_name_display: PanelContainer = %ZoneNameDisplay
@onready var zone_unlocked_display: CanvasLayer = %ZoneUnlockedDisplay
@onready var input_hud: InputHud = %InputHud


func _ready() -> void:
	GameState.global.zone_changed.connect(_on_zone_changed)
	get_tree().scene_changed.connect(_on_scene_changed)

	# When running a scene that contains a player directly, this node becomes
	# ready before the player. Defer the initial setup so that we can assume the
	# whole scene (and in particular the player) is ready in
	# _on_scene_changed(). This does not occur in normal gameplay because the
	# main scene does not have a player (or sokoban ruleset), but is harmless in
	# that case.
	_on_scene_changed.call_deferred()


func _on_scene_changed() -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	var sokoban_ruleset: RuleEngine = get_tree().get_first_node_in_group("sokoban_ruleset")
	input_hud.player = player
	input_hud.sokoban_ruleset = sokoban_ruleset
	input_hud.update_visibility()
	story_quest_progress.player = player
	story_quest_progress.sokoban_ruleset = sokoban_ruleset
	story_quest_progress.update_visibility()


## Force a refresh of the StoryQuest progress.
func refresh_story_quest_progress() -> void:
	story_quest_progress.update_visibility()


## Force a refresh of input hints.
func refresh_input_hud() -> void:
	input_hud.update_visibility()


func _on_zone_changed(zone_name: String, first_visit: bool) -> void:
	if GameState.scene.zone_name_displayed == zone_name:
		return
	GameState.scene.zone_name_displayed = zone_name
	if first_visit:
		zone_unlocked_display.animate(zone_name)
	else:
		zone_name_display.animate(zone_name)
