# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends CanvasLayer

var player: Player

@onready var normal_controls: HBoxContainer = $TabContainer/NormalControls
@onready var repel_input_hint: HBoxContainer = $TabContainer/NormalControls/RepelInputHint
@onready var aim_input_hint: HBoxContainer = $TabContainer/NormalControls/AimInputHint
@onready var throw_input_hint: HBoxContainer = $TabContainer/NormalControls/ThrowInputHint
@onready var sokoban_controls: HBoxContainer = $TabContainer/SokobanControls
@onready var skip_input_hint: HBoxContainer = $TabContainer/SokobanControls/SkiptInputHint
@onready var interact_input_hint: HBoxContainer = $TabContainer/NormalControls/InteractInputHint


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

	# When running a scene that contains a player directly, this node becomes
	# ready before the player. Defer the initial setup so that we can assume the
	# whole scene (and in particular the player) is ready in
	# _on_scene_changed(). This does not occur in normal gameplay because the
	# main scene does not have a player (or sokoban ruleset), but is harmless in
	# that case.
	_on_scene_changed.call_deferred()


func _on_scene_changed() -> void:
	player = get_tree().get_first_node_in_group("player")
	var sokoban_ruleset: RuleEngine = get_tree().get_first_node_in_group("sokoban_ruleset")

	if player:
		visible = true
		normal_controls.visible = true

		player.player_interaction.can_interact_changed.connect(_update_player_state)
		player.player_repel.visibility_changed.connect(_update_player_state)
		player.player_hook.visibility_changed.connect(_update_player_state)

		_update_player_state()
	elif sokoban_ruleset:
		visible = true
		sokoban_controls.visible = true
		skip_input_hint.visible = false
		sokoban_ruleset.skip_enabled.connect(_display_skip)
	else:
		visible = false


func _update_player_state() -> void:
	interact_input_hint.visible = player.player_interaction.can_interact()

	repel_input_hint.visible = player.player_repel.visible

	throw_input_hint.visible = player.player_hook.visible
	aim_input_hint.visible = player.player_hook.visible


func _display_skip() -> void:
	skip_input_hint.visible = true
