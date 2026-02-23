extends Node
## Registry of action names for each player
##
## This game has actions preconfigured for two players. The [Player] scene can be configured
## to respond to inputs for player one or two, or for both players.
## [br][br]
## Use [method lookup] to find the full action name for a given player and action.

## Short names for actions available to each player. Use [method lookup] to find the full action
## name for a given player and action.
const ACTIONS = [
	&"jump",
	&"left",
	&"right",
	&"teleport",
	&"phase",
	&"shrink",
]

# Dictionary[Global.Player, Dictionary[StringName, StringName]]
# e.g. _player_actions[Global.Player.ONE][&"jump"] == &"player_1_jump"
@onready var _player_actions = _setup_both_actions()


# Creates the mapping from Global.Player enum & elements of ACTIONS to full action name, and creates
# the "both" actions bound to the combination of events for players one and two. This is done
# dynamically so that we don't have to keep them in sync in the project settings.
func _setup_both_actions() -> Dictionary[Global.Player, Dictionary]:
	var player_actions: Dictionary[Global.Player, Dictionary] = {
		Global.Player.ONE: {}, Global.Player.TWO: {}, Global.Player.BOTH: {}
	}

	for action: StringName in ACTIONS:
		var p1: StringName = "player_1_" + action
		var p2: StringName = "player_2_" + action
		var both: StringName = "player_both_" + action

		player_actions[Global.Player.ONE][action] = p1
		player_actions[Global.Player.TWO][action] = p2
		player_actions[Global.Player.BOTH][action] = both

		var deadzone := maxf(InputMap.action_get_deadzone(p1), InputMap.action_get_deadzone(p2))
		InputMap.add_action(both, deadzone)

		for event: InputEvent in InputMap.action_get_events(p1) + InputMap.action_get_events(p2):
			InputMap.action_add_event(both, event)

	return player_actions


## Looks up the full action name for [param player] and [param action]. These full names can be
## passed to methods such as [method Input.is_action_pressed].
## [br][br]
## For example, [code]Actions.lookup(Global.Player.TWO, "jump")[/code] returns
## [code]"player_2_jump"[/code].
func lookup(player: Global.Player, action: StringName) -> StringName:
	return _player_actions[player][action]
