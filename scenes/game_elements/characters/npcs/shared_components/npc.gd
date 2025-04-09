# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name NPC
extends CharacterBody2D

enum LookAtSide {
	LEFT = -1,
	RIGHT = 1,
}

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload(
	"res://scenes/game_elements/characters/shared_components/sprite_frames/sprite_frame_01.tres"
)

@export var look_at_side: LookAtSide = LookAtSide.LEFT:
	set = _set_look_at_side

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_look_at_side(new_look_at_side: LookAtSide) -> void:
	look_at_side = new_look_at_side
	if not is_node_ready():
		return
	animated_sprite_2d.flip_h = look_at_side == LookAtSide.LEFT


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	animated_sprite_2d.sprite_frames = new_sprite_frames
	if not Engine.is_editor_hint():
		animated_sprite_2d.play(animated_sprite_2d.autoplay)


func _ready() -> void:
	_set_look_at_side(look_at_side)
	_set_sprite_frames(sprite_frames)
