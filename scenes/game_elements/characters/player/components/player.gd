# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

signal mode_changed(mode: Mode)

## Controls how the player can interact with the world around them.
enum Mode {
	## Player can explore the world, interact with items and NPCs, but is not
	## engaged in combat. Combat actions are not available in this mode.
	COZY,
	## Player is engaged in combat. Player can use combat actions.
	FIGHTING,
	## Player is using the grappling hook.
	HOOKING,
	## Player can't be controlled anymore.
	DEFEATED,
}

## The animations which must be provided by [member sprite_frames], each with the corresponding
## number of frames.
const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10,
	&"walk": 6,
	&"attack_01": 4,
	&"attack_02": 4,
	&"defeated": 11,
}

## Optional animations which, if provided by [member sprite_frames], must have the corresponding
## number of frames.
const OPTIONAL_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"run": 6,
}

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

## The character's name. This is used to highlight when the player's character
## is speaking during dialogue.
@export var player_name: String = "Player Name"

## Controls how the player can interact with the world around them.
@export var mode: Mode = Mode.COZY:
	set = _set_mode

## The character walking speed.
@export_range(10, 100000, 10) var walk_speed: float = 300.0

## The character running speed.
@export_range(10, 100000, 10) var run_speed: float = 500.0

## The character speed when aiming with the grappling hook.
@export_range(10, 100000, 10) var aiming_speed: float = 100.0

## How fast does the player transition from walking/running to stopped.
## A low value will make the character look as slipping on ice.
## A high value will stop the character immediately.
@export_range(10, 100000, 10) var stopping_step: float = 1500.0

## How fast does the player transition from stopped to walking/running.
@export_range(10, 100000, 10) var moving_step: float = 4000.0

## The SpriteFrames must have specific animations with a certain amount of frames.
## See [constant REQUIRED_ANIMATION_FRAMES] and [constant OPTIONAL_ANIMATION_FRAMES].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds")
## Sound that plays for each step during the walk animation
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

var input_vector: Vector2

@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_fighting: Node2D = %PlayerFighting
@onready var player_hook: PlayerHook = %PlayerHook
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound


func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode
	if not is_node_ready():
		return
	match mode:
		Mode.COZY:
			_toggle_player_behavior(player_interaction, true)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)
		Mode.FIGHTING:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, true)
			_toggle_player_behavior(player_hook, false)
		Mode.HOOKING:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, true)
		Mode.DEFEATED:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)
	if mode != previous_mode:
		mode_changed.emit(mode)


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	player_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	for animation: StringName in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	var animations: Dictionary[StringName, int] = REQUIRED_ANIMATION_FRAMES.merged(
		OPTIONAL_ANIMATION_FRAMES
	)
	for animation: StringName in animations:
		if not sprite_frames.has_animation(animation):
			continue

		var count := sprite_frames.get_frame_count(animation)
		var expected_count := animations[animation]

		if count != expected_count:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [animation, count, expected_count]
				)
			)

	return warnings


func _ready() -> void:
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)


func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var speed: float
	if player_hook.is_throwing_or_aiming():
		speed = aiming_speed
	elif Input.is_action_pressed(&"running"):
		speed = run_speed
	else:
		speed = walk_speed

	input_vector = axis * speed


## Returns [code]true[/code] if the player is running. When using an analogue joystick, this can be
## [code]false[/code] even if the player is holding the "run" button, because the joystick may be
## inclined only slightly.
func is_running() -> bool:
	# While walking diagonally with an analogue joystick, the input vector can be fractionally
	# greater than walk_speed, due to trigonometric/floating-point inaccuracy.
	return input_vector.length_squared() > (walk_speed * walk_speed) + 1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# While pulling the grappling hook, the movement is handled in PlayerHook._process.
	if player_hook.pulling:
		return

	if player_interaction.is_interacting or mode == Mode.DEFEATED:
		velocity = Vector2.ZERO
		return

	var step := (
		stopping_step if velocity.length_squared() > input_vector.length_squared() else moving_step
	)
	velocity = velocity.move_toward(input_vector, step * delta)

	move_and_slide()


func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		%PlayerSprite.look_at_side(look_side)
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position


func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready():
		await ready
	_walk_sound.stream = walk_sound_stream
