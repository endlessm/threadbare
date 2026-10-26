# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHud
extends Control

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine
@export var displaying_dialogue: bool

var player_interaction: PlayerInteraction
var player_repel: PlayerRepel
var player_hook: PlayerHook

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


func _on_input_device_changed(_device: String, _device_index: int) -> void:
	_update_player_state()


func update_visibility() -> void:
	visible = (
		not Settings.touch_controls and Settings.show_input_hud and not get_tree().paused
		and not Transitions.is_running() and not displaying_dialogue and (player or sokoban_ruleset)
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

	var has_hook: bool = player_hook and player_hook.visible
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
