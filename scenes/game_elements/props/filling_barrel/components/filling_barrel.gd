# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FillingBarrel
extends StaticBody2D
## A barrel that starts empty and gets filled until completion
##
## @tutorial: https://github.com/endlessm/threadbare/discussions/1323
##
## This is a piece of the fill-matching mechanic.
## [br][br]
## Call [member fill()] to increment the amount. When
## [member needed_amount] is reached, the [signal completed]
## is emited.

## Emited when the barrel amount reaches [member needed_amount].
signal completed

const DEFAULT_SPRITE_FRAMES: SpriteFrames = preload("uid://dlsq0ke41s1yh")
const FILLING_NAME_ANIMATION: StringName = &"filling"

## Determines how the FillingBarrel looks.[br]
## It is required that the [member sprite_frames] have an animation called filling.[br]
## The barrel default sprite will be the first frame of that animation, and it
## advances frames as it is being filled.
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAMES:
	set = _set_sprite_frames

## The amount of times the barrel needs to be filled.[br]
## When the barrel is filled that many times, it emits [signal completed].
@export var needed_amount: int = 3

## Projectiles with this label fill the barrel.
@export var label: String = "???"

## Optional color to tint the barrel.
@export var color: Color:
	set = _set_color

var _amount: int = 0

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var hit_box: StaticBody2D = %HitBox


func _set_color(new_color: Color) -> void:
	color = new_color
	if not is_node_ready():
		return
	if color:
		animated_sprite_2d.modulate = color
	else:
		animated_sprite_2d.modulate = Color.WHITE


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames if new_sprite_frames else DEFAULT_SPRITE_FRAMES
	if not is_node_ready():
		return
	if animated_sprite_2d:
		animated_sprite_2d.sprite_frames = sprite_frames
	update_configuration_warnings()


func _ready() -> void:
	_set_color(color)
	_set_sprite_frames(sprite_frames)
	animated_sprite_2d.animation = FILLING_NAME_ANIMATION
	animated_sprite_2d.frame = 0


## Increment the amount and play an animation. If completed, also play the completed
## animation and remove this barrel from the current scene.
func increment(by: int = 1) -> void:
	if _amount >= needed_amount:
		return
	animation_player.play(&"increment")
	_amount += by
	animated_sprite_2d.frame = floor(float(_amount) / needed_amount * _total_frames())
	if _amount >= needed_amount:
		_disable_collisions.call_deferred()
		await animation_player.animation_finished
		animation_player.play(&"completed")
		await animation_player.animation_finished
		queue_free()
		completed.emit()


func _disable_collisions() -> void:
	hit_box.process_mode = Node.PROCESS_MODE_DISABLED
	collision_shape_2d.disabled = true


func _total_frames() -> int:
	return animated_sprite_2d.sprite_frames.get_frame_count(FILLING_NAME_ANIMATION)


func _get_configuration_warnings() -> PackedStringArray:
	if not sprite_frames.has_animation(FILLING_NAME_ANIMATION):
		return ["sprite_frames is missing the following animation: %s" % FILLING_NAME_ANIMATION]

	if sprite_frames.get_frame_count(FILLING_NAME_ANIMATION) < 2:
		return ["sprite_frames %s animation must have at least 2 frames" % FILLING_NAME_ANIMATION]

	return []
