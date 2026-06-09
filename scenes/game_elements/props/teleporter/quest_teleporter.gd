# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name QuestTeleporter
extends Area2D
## Starts a quest when the player enters this area

## Quest to start when entering this area.
@export var quest: LoreQuest:
	set = set_quest

## Spawn point in the current scene to place the player at if they abandon the
## quest. Should be outside this area.
@export var abandon_point: SpawnPoint:
	set = set_abandon_point

## Transition to use at the start of the switch to [member quest].
@export var enter_transition: Transition.Effect:
	set = set_enter_transition

@onready var scene_link: SceneLink = %SceneLink


#region Standard stuff
func _ready() -> void:
	set_quest(quest)
	set_enter_transition(enter_transition)

	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	if not quest:
		warnings.append("Quest not set")
	if not abandon_point:
		warnings.append("Abandon Point not set")
	return warnings


#endregion


#region Setters
func set_quest(new_value: LoreQuest) -> void:
	quest = new_value
	update_configuration_warnings()


func set_abandon_point(new_value: SpawnPoint) -> void:
	abandon_point = new_value
	update_configuration_warnings()


func set_enter_transition(new_value: Transition.Effect) -> void:
	enter_transition = new_value
	if scene_link:
		scene_link.enter_transition = new_value


#endregion


#region Callbacks
func _on_body_entered(body: Node2D) -> void:
	if not quest:
		push_warning("%s: no quest" % get_path())
		return

	if not body is Player:
		return

	GameState.start_quest(quest)
	var current_scene := get_tree().current_scene
	GameState.quest.abandon_scene_path = current_scene.scene_file_path
	GameState.quest.abandon_spawn_point = current_scene.get_path_to(abandon_point)
	scene_link.switch()

#endregion
