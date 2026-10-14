# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine
@export var displaying_dialogue: bool

var player_interaction: PlayerInteraction
var player_repel: PlayerRepel
var player_hook: PlayerHook

@onready var interact_button: TouchScreenButton = %InteractButton
@onready var repel_button: TouchScreenButton = %RepelButton
@onready var virtual_joystick: VirtualJoystick = %VirtualJoystick


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	# TouchScreenButton doesn't mark its touches as handled, so the game would
	# also get them. For example, tapping the interact button would throw the
	# grappling hook too.
	for button: TouchScreenButton in [interact_button, repel_button]:
		button.pressed.connect(get_viewport().set_input_as_handled)
		button.released.connect(get_viewport().set_input_as_handled)
	Transitions.started.connect(update_visibility)
	Transitions.finished.connect(update_visibility)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			update_visibility()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_virtual_joystick()


## Release the virtual joystick and the movement actions it keeps pressed.
## [br][br]
## A hidden [VirtualJoystick] doesn't receive the touch release, so if it's
## hidden while touched, for example by a transition, the player would keep
## walking. It has no public method to reset it, but changing its size resets
## it, so change the size and put it back.
func _reset_virtual_joystick() -> void:
	var tip_size := virtual_joystick.tip_size
	virtual_joystick.tip_size = tip_size + 1.0
	virtual_joystick.tip_size = tip_size


func update_visibility() -> void:
	visible = (
		DisplayServer.is_touchscreen_available()
		and not get_tree().paused
		and not Transitions.is_running()
		and not displaying_dialogue
		and (player or sokoban_ruleset)
	)

	if player:
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


func _update_player_state() -> void:
	if player_interaction:
		var action := player_interaction.get_interact_action()
		interact_button.visible = not action.is_empty()
	else:
		interact_button.visible = false

	repel_button.visible = player_repel and player_repel.visible and not interact_button.visible
