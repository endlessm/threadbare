# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

var player: CharacterBody2D
var player_interaction: PlayerInteraction
var player_repel: PlayerRepel
var player_hook: PlayerHook

var sokoban_ruleset: RuleEngine

@onready var normal_controls := %NormalControls
@onready var interact_input_hint := %InteractInputHint
@onready var aim_input_hint := %AimInputHint
@onready var throw_input_hint := %ThrowInputHint
@onready var repel_input_hint := %RepelInputHint

@onready var sokoban_controls := %SokobanControls
@onready var skip_input_hint := %SkipInputHint


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

	Transitions.started.connect(_update_visibility)
	Transitions.finished.connect(_update_visibility)

	# When running a scene that contains a player directly, this node becomes
	# ready before the player. Defer the initial setup so that we can assume the
	# whole scene (and in particular the player) is ready in
	# _on_scene_changed(). This does not occur in normal gameplay because the
	# main scene does not have a player (or sokoban ruleset), but is harmless in
	# that case.
	_on_scene_changed.call_deferred()


func _on_scene_changed() -> void:
	player = get_tree().get_first_node_in_group("player")
	sokoban_ruleset = get_tree().get_first_node_in_group("sokoban_ruleset")

	_update_visibility()

	if player:
		normal_controls.visible = true

		player_interaction = player.get("player_interaction") as PlayerInteraction
		if player_interaction:
			player_interaction.can_interact_changed.connect(_update_player_state)

		player_repel = player.get("player_repel") as PlayerRepel
		if player_repel:
			player_repel.visibility_changed.connect(_update_player_state)

		player_hook = player.get("player_hook") as PlayerHook
		if player_hook:
			player_hook.visibility_changed.connect(_update_player_state)

		_update_player_state()
	elif sokoban_ruleset:
		sokoban_controls.visible = true
		skip_input_hint.visible = false
		sokoban_ruleset.skip_enabled.connect(_display_skip)


func _update_visibility() -> void:
	visible = not get_tree().paused and not Transitions.is_running() and (player or sokoban_ruleset)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			_update_visibility()


func _update_player_state() -> void:
	interact_input_hint.visible = player_interaction and player_interaction.can_interact()

	repel_input_hint.visible = player_repel and player_repel.visible

	throw_input_hint.visible = player_hook and player_hook.visible
	aim_input_hint.visible = player_hook and player_hook.visible


func _display_skip() -> void:
	skip_input_hint.visible = true
