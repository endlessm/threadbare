# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

## Controls how the player can interact with the world around them.
enum Mode {
	## Player can explore the world, interact with items and NPCs, but is not
	## engaged in combat. Combat actions are not available in this mode.
	COZY,
	## Player is engaged in combat. Player can use combat actions.
	FIGHTING,
}

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10,
	&"walk": 6,
	&"attack_01": 4,
	&"attack_02": 4,
}
const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://dtoylirwywk0j")

## The character's name. This is used to highlight when the player's character
## is speaking during dialogue.
@export var player_name: String = "StoryWeaver"

## Controls how the player can interact with the world around them.
@export var mode: Mode = Mode.COZY:
	set = _set_mode
@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0
@export_range(10, 100000, 10) var stopping_step: float = 1500.0
@export_range(10, 100000, 10) var moving_step: float = 4000.0

## The SpriteFrames must have specific animations with a certain amount of frames.
## See [member REQUIRED_ANIMATION_FRAMES].
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

var input_vector: Vector2

@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_fighting: Node2D = %PlayerFighting
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if not is_node_ready():
		return
	match mode:
		Mode.COZY:
			_toggle_player_behavior(player_interaction, true)
			_toggle_player_behavior(player_fighting, false)
		Mode.FIGHTING:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, true)


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
	var warnings = []
	for animation in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
		elif sprite_frames.get_frame_count(animation) != REQUIRED_ANIMATION_FRAMES[animation]:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [
						animation,
						sprite_frames.get_frame_count(animation),
						REQUIRED_ANIMATION_FRAMES[animation]
					]
				)
			)
	return warnings


func _ready() -> void:
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)


func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")

	var speed: float
	if Input.is_action_pressed(&"running"):
		speed = run_speed
	else:
		speed = walk_speed

	input_vector = axis * speed


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player_interaction.is_interacting:
		velocity = Vector2.ZERO
		return

	var step: float
	if input_vector.is_zero_approx():
		step = stopping_step
	else:
		step = moving_step

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
