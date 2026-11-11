# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Control

## Theme type variations of the input hint labels, without and with
## [member Settings.large_text].
const HINT_LABEL_TYPE_VARIATION := &"HintLabel"
const LARGE_HINT_LABEL_TYPE_VARIATION := &"LargeHintLabel"

## The left and right anchors of the virtual joystick area, in each layout. The
## right-handed ones must match the scene.
const RIGHT_HANDED_JOYSTICK_ANCHORS := Vector2(0.0, 0.4)
const LEFT_HANDED_JOYSTICK_ANCHORS := Vector2(0.6, 1.0)

@export var player: CharacterBody2D
@export var sokoban_ruleset: RuleEngine
@export var displaying_dialogue: bool

## Preview the layout of [member Settings.left_handed] in the editor.
@export_tool_button(
	"Left-handed layout"
) var left_handed_editor_button: Callable = preview_left_handed_layout

## Preview the default layout in the editor.
@export_tool_button(
	"Right-handed layout"
) var right_handed_editor_button: Callable = preview_right_handed_layout

var player_interaction: PlayerInteraction
var player_repel: PlayerRepel
var player_hook: PlayerHook

## Where each finger that may be tapping touched the screen, by finger index.
## A finger is forgotten once it moves far enough to be a swipe instead.
var _tap_start_positions: Dictionary[int, Vector2]

@onready var pause_button: TouchScreenButton = %PauseButton
@onready var virtual_joystick: VirtualJoystick = %VirtualJoystick
@onready var swipe_input_hint: Control = %SwipeInputHint
@onready var tap_input_hint: LabeledInputHint = %TapInputHint
@onready var virtual_joystick_container: Control = %VirtualJoystickContainer
@onready var touch_input_hints: MarginContainer = %TouchInputHints
@onready var input_hints_box: BoxContainer = %InputHintsBox


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return

	visibility_changed.connect(_on_visibility_changed)
	# TouchScreenButton doesn't mark its touches as handled, so the game would
	# also get them. For example, tapping the pause button would also be a tap
	# for the game.
	pause_button.pressed.connect(get_viewport().set_input_as_handled)
	pause_button.released.connect(get_viewport().set_input_as_handled)
	Transitions.started.connect(update_visibility)
	Transitions.finished.connect(update_visibility)
	Settings.touch_controls_changed.connect(update_visibility)
	Settings.left_handed_changed.connect(_on_left_handed_changed)
	_on_left_handed_changed()


func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			update_visibility()


func _on_left_handed_changed() -> void:
	set_left_handed_layout(Settings.left_handed)


func preview_left_handed_layout() -> void:
	set_left_handed_layout(true)


func preview_right_handed_layout() -> void:
	set_left_handed_layout(false)


## Mirror the touch controls horizontally for left-handed players, or put them
## back. The virtual joystick goes to the opposite bottom corner, and the input
## hints to the opposite side. The pause button doesn't move, because the top
## right corner is for other parts of the HUD.
func set_left_handed_layout(left_handed: bool) -> void:
	var joystick_anchors := (
		LEFT_HANDED_JOYSTICK_ANCHORS if left_handed else RIGHT_HANDED_JOYSTICK_ANCHORS
	)
	# Set first the side that moves towards the edge of the screen. Otherwise
	# one anchor would cross the other, and Control would clamp it.
	var sides := [SIDE_RIGHT, SIDE_LEFT] if left_handed else [SIDE_LEFT, SIDE_RIGHT]
	for side: Side in sides:
		var anchor := joystick_anchors.x if side == SIDE_LEFT else joystick_anchors.y
		virtual_joystick_container.set_anchor_and_offset(side, anchor, 0.0, false)
	virtual_joystick_container.grow_horizontal = (
		Control.GROW_DIRECTION_BEGIN if left_handed else Control.GROW_DIRECTION_END
	)

	input_hints_box.alignment = (
		BoxContainer.ALIGNMENT_BEGIN if left_handed else BoxContainer.ALIGNMENT_END
	)
	# Keep the swipe hint next to the edge of the screen, so it doesn't move
	# when the text of the tap hint changes, for example from repel to interact.
	input_hints_box.move_child(swipe_input_hint, 0 if left_handed else -1)

	# Keep the margin on the side of the edge of the screen.
	var margin := maxi(
		touch_input_hints.get_theme_constant(&"margin_left"),
		touch_input_hints.get_theme_constant(&"margin_right"),
	)
	touch_input_hints.remove_theme_constant_override(&"margin_left")
	touch_input_hints.remove_theme_constant_override(&"margin_right")
	touch_input_hints.add_theme_constant_override(
		&"margin_left" if left_handed else &"margin_right",
		margin,
	)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_virtual_joystick()
		_tap_start_positions.clear()


## Tapping anywhere else than the pause button and the virtual joystick
## interacts, or repels if there is nothing to interact with. See
## [method _get_tap_action]. The pause button and the virtual joystick handle
## their own touches, so those don't get here. A finger that moves at least
## [constant HookControl.SWIPE_MIN_DISTANCE] is a swipe, which throws the
## grappling hook instead. See [HookControl].
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if event.index in _tap_start_positions and _is_swipe(event):
			_tap_start_positions.erase(event.index)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if is_visible_in_tree():
				_tap_start_positions[event.index] = event.position
		elif event.index in _tap_start_positions:
			var is_tap: bool = not event.canceled and not _is_swipe(event)
			_tap_start_positions.erase(event.index)
			if is_tap and is_visible_in_tree():
				var tap_action := _get_tap_action()
				if not tap_action.is_empty():
					_press_action_once(tap_action)


func _is_swipe(event: InputEvent) -> bool:
	var distance: float = event.position.distance_to(_tap_start_positions[event.index])
	return distance >= HookControl.SWIPE_MIN_DISTANCE


## The action that a tap presses: interact when there is something to
## interact with, otherwise repel if the player can. Empty if neither.
func _get_tap_action() -> StringName:
	if player_interaction and not player_interaction.get_interact_action().is_empty():
		return &"interact"
	if player_repel and player_repel.visible:
		return &"repel"
	return &""


## Press and release [param action], like a [TouchScreenButton] does with its
## action.
## [br][br]
## The release waits for a later frame. If both happened in the same frame,
## [method Input.is_action_just_pressed] would still be true when handling the
## release, and for example [PlayerRepel] would keep repelling. Neither the next
## [signal SceneTree.process_frame] nor a short timer guarantee a later frame:
## the first is emitted in the same frame, and the second too if the frame is
## slow.
func _press_action_once(action: StringName) -> void:
	_push_action(action, true)
	var press_frame := Engine.get_process_frames()
	while Engine.get_process_frames() == press_frame:
		await get_tree().process_frame
	_push_action(action, false)


func _push_action(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	get_viewport().push_input(action_event)


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
		Settings.touch_controls and not get_tree().paused and not Transitions.is_running()
		and not displaying_dialogue and (player or sokoban_ruleset)
	)

	_update_hint_labels_font()

	if not player:
		swipe_input_hint.visible = false
		tap_input_hint.visible = false
	else:
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


## Apply [member Settings.large_text]. It's checked each time the touch controls
## are shown, instead of once, because this node lives as long as the game, and
## the player may change the setting meanwhile in the pause menu.
func _update_hint_labels_font() -> void:
	var type_variation := (
		LARGE_HINT_LABEL_TYPE_VARIATION if Settings.large_text else HINT_LABEL_TYPE_VARIATION
	)
	for hint: Control in [swipe_input_hint, tap_input_hint]:
		for label: Label in hint.find_children("*", "Label", true, false):
			label.theme_type_variation = type_variation


func _update_player_state() -> void:
	swipe_input_hint.visible = player_hook and player_hook.visible

	var tap_action := _get_tap_action()
	tap_input_hint.visible = not tap_action.is_empty()
	match tap_action:
		&"interact":
			tap_input_hint.text = player_interaction.get_interact_action()
		&"repel":
			# The label translates it.
			tap_input_hint.text = "Repel"
