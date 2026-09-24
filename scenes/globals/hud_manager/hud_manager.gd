# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node

const SCENES_WITHOUT_HUD: Array[String] = [
	"uid://huuo8mnwsphv",  # splash.tscn
	"uid://stdqc6ttomff",  # title_screen.tscn
]

@onready var _hud: Hud = %Hud
@onready var _input_hud: InputHud = %InputHud


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred()


func _on_scene_changed() -> void:
	refresh_hud()


func refresh_hud() -> void:
	var show := _should_show_hud()
	if show:
		_hud.show_story_quest_progress()
	else:
		_hud.hide_story_quest_progress()


func show_hud() -> void:
	_hud.show_story_quest_progress()


func _should_show_hud() -> bool:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return false

	var scene_uid := ResourceUID.id_to_text(
		ResourceLoader.get_resource_uid(current_scene.scene_file_path)
	)
	if scene_uid in SCENES_WITHOUT_HUD:
		return false

	if not GameState.quest or GameState.quest.quest.threads_to_collect <= 0:
		return false

	if current_scene is FraysEnd:
		return GameState.quest.inventory.items.size() >= GameState.quest.quest.threads_to_collect

	var scene_path := current_scene.scene_file_path
	if scene_path.begins_with("res://scenes/world_map/"):
		return false

	return _scene_has_gameplay_avatar()


func _scene_has_gameplay_avatar() -> bool:
	return (
		get_tree().get_first_node_in_group("player") != null
		or get_tree().get_first_node_in_group("sokoban_ruleset") != null
	)


func refresh_input_hud() -> void:
	_input_hud.refresh_scene_status()
