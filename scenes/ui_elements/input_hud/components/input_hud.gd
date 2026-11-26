# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHud
extends Control

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine
@export var displaying_dialogue: bool

var player_interaction: PlayerInteraction

@onready var normal_controls := %NormalControls
@onready var move_label: Label = %MovementInputHint/Label
@onready var move_aim_label: Label = %MovementInputHint/MoveAimLabel
@onready var interact_input_hint: LabeledInputHint = %InteractInputHint
@onready var aim_input_hint := %AimInputHint
@onready var throw_input_hint := %ThrowInputHint
@onready var repel_input_hint := %RepelInputHint

@onready var sokoban_controls := %SokobanControls
@onready var skip_input_hint := %SkipInputHint


func _ready() -> void:
	Transitions.started.connect(update_visibility)
	Transitions.finished.connect(update_visibility)
	Settings.touch_controls_changed.connect(update_visibility)
	Settings.keyboard_only_changed.connect(_update_player_state)
	InputHelper.device_changed.connect(_on_input_device_changed)
	GameState.player.abilities_changed.connect(_update_player_state)
	GameState.player_changed.connect(_on_player_state_changed)


func _on_input_device_changed(_device: String, _device_index: int) -> void:
	_update_player_state()


func _on_player_state_changed(old_state: PlayerState, new_state: PlayerState) -> void:
	old_state.abilities_changed.disconnect(_update_player_state)
	new_state.abilities_changed.connect(_update_player_state)
	_update_player_state()


func _on_player_mode_changed(_mode: Player.Mode) -> void:
	update_visibility()


func update_visibility() -> void:
	var player_node := player as Player
	if player_node and not player_node.mode_changed.is_connected(_on_player_mode_changed):
		player_node.mode_changed.connect(_on_player_mode_changed)

	# The controls don't apply while the player is defeated. While controlled by
	# other means, like when pulled by the hook, the player can still repel, so
	# keep the hints.
	var is_defeated := player_node and player_node.mode == Player.Mode.DEFEATED

	visible = (
		not Settings.touch_controls and Settings.show_input_hud
		and not get_tree().paused and not Transitions.is_running()
		and not displaying_dialogue and (player or sokoban_ruleset) and not is_defeated
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

	# Hum is a modifier of Repel, so both use the Repel input hint.
	# TODO: Maybe the text in the label should change to "repel" or "hum".
	repel_input_hint.visible = GameState.player.has_ability(Enums.PlayerAbilities.ABILITY_A)

	var has_hook := GameState.player.has_ability(Enums.PlayerAbilities.ABILITY_B)
	throw_input_hint.visible = has_hook

	# With the keyboard only, the same keys move and aim, so a single hint
	# labeled "Move / Aim" replaces the two identical ones.
	var aims_with_move_keys := (
		has_hook and Settings.keyboard_only and InputHelper.device == InputHelper.DEVICE_KEYBOARD
	)
	aim_input_hint.visible = has_hook and not aims_with_move_keys
	move_label.visible = not aims_with_move_keys
	move_aim_label.visible = aims_with_move_keys


func _display_skip() -> void:
	skip_input_hint.visible = true
