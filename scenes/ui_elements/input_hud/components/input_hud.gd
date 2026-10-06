# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHud
extends Control

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine

var player_interaction: PlayerInteraction
var player_repel: PlayerRepel
var player_hook: PlayerHook

var displaying_dialogue: bool

@onready var normal_controls := %NormalControls
@onready var interact_input_hint: LabeledInputHint = %InteractInputHint
@onready var aim_input_hint := %AimInputHint
@onready var throw_input_hint := %ThrowInputHint
@onready var repel_input_hint := %RepelInputHint

@onready var sokoban_controls := %SokobanControls
@onready var skip_input_hint := %SkipInputHint


func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	Transitions.started.connect(update_visibility)
	Transitions.finished.connect(update_visibility)


func update_visibility() -> void:
	visible = (
		Settings.show_input_hud
		and not get_tree().paused
		and not Transitions.is_running()
		and not displaying_dialogue
		and (player or sokoban_ruleset)
	)
	if not visible:
		return

	if player:
		normal_controls.visible = true

		player_interaction = player.get("player_interaction") as PlayerInteraction
		if (
			player_interaction
			and not player_interaction.interact_action_changed.is_connected(_update_player_state)
		):
			player_interaction.interact_action_changed.connect(_update_player_state)

		player_repel = player.get("player_repel") as PlayerRepel
		if player_repel and not player_repel.visibility_changed.is_connected(_update_player_state):
			player_repel.visibility_changed.connect(_update_player_state)

		player_hook = player.get("player_hook") as PlayerHook
		if player_hook and not player_hook.visibility_changed.is_connected(_update_player_state):
			player_hook.visibility_changed.connect(_update_player_state)

		_update_player_state()
	elif sokoban_ruleset:
		sokoban_controls.visible = true
		skip_input_hint.visible = false
		sokoban_ruleset.skip_enabled.connect(_display_skip)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			update_visibility()


func _update_player_state() -> void:
	if player_interaction:
		var action := player_interaction.get_interact_action()
		interact_input_hint.visible = not action.is_empty()
		interact_input_hint.text = action
	else:
		interact_input_hint.visible = false

	repel_input_hint.visible = player_repel and player_repel.visible

	throw_input_hint.visible = player_hook and player_hook.visible
	aim_input_hint.visible = player_hook and player_hook.visible


func _on_dialogue_started(_resource: DialogueResource) -> void:
	displaying_dialogue = true
	update_visibility()


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	displaying_dialogue = false
	update_visibility()


func _display_skip() -> void:
	skip_input_hint.visible = true
