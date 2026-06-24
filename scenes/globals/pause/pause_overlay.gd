# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

@export_file("*.tscn") var title_scene: String
@export_file("*.tscn") var frays_end: String
@export var abandon_dialogue: DialogueResource

@onready var tab_container: TabContainer = %TabContainer
@onready var pause_menu: Control = %Menu
@onready var back_button: Button = %BackButton
@onready var options: Control = %Options
@onready var abandon_quest_button: Button = %AbandonQuestButton
@onready var skip_tutorial_button: Button = %SkipTutorialButton


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var new_state := not get_tree().paused
	visible = new_state
	get_tree().paused = new_state

	Input.set_default_cursor_shape(Input.CURSOR_ARROW if new_state else Input.CURSOR_CROSS)

	if new_state:
		if not GameState.quest:
			skip_tutorial_button.hide()
			abandon_quest_button.hide()
		elif GameState.quest.quest is LoreQuest and GameState.quest.quest.skippable:
			skip_tutorial_button.show()
			abandon_quest_button.hide()
		else:
			skip_tutorial_button.hide()
			abandon_quest_button.show()
		pause_menu.show()
		back_button.grab_focus()


func _on_abandon_quest_pressed() -> void:
	toggle_pause()
	abandon_quest()


func abandon_quest(suspend: bool = true) -> void:
	if not GameState.quest:
		push_warning("No quest to abandon")
		return

	var quest := GameState.quest.quest
	var abandon_scene := GameState.quest.abandon_scene_path
	var abandon_spawn_point: NodePath
	if abandon_scene:
		abandon_spawn_point = GameState.quest.abandon_spawn_point
	else:
		abandon_scene = frays_end

	GameState.abandon_quest(suspend)
	SceneSwitcher.change_to_file_with_transition(
		abandon_scene, abandon_spawn_point, Transition.Effect.FADE, Transition.Effect.FADE
	)
	await Transitions.finished

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var replaying := quest in GameState.global.completed_quests
	var title := "abandoned_replay" if replaying else "abandoned"
	DialogueManager.show_dialogue_balloon(abandon_dialogue, title, [player])


func _on_skip_tutorial_pressed() -> void:
	toggle_pause()
	var lq := GameState.quest.quest as LoreQuest
	for ability: Enums.PlayerAbilities in lq.skip_abilities:
		GameState.player.set_ability(ability, true)
	GameState.mark_quest_completed()
	SceneSwitcher.change_to_file_with_transition(
		frays_end, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _on_options_back() -> void:
	toggle_pause()


func _on_back_button_pressed() -> void:
	toggle_pause()


func _on_title_screen_button_pressed() -> void:
	toggle_pause()
	SceneSwitcher.change_to_file_with_transition(
		title_scene, ^"", Transition.Effect.FADE, Transition.Effect.FADE
	)


func _on_menu_visibility_changed() -> void:
	if not is_node_ready():
		return
	if pause_menu.visible:
		back_button.grab_focus()


func _on_inventory_back() -> void:
	toggle_pause()
