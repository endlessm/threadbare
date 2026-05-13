# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var treetop_sprite_frames: SpriteFrames = preload("uid://d2i5boaxe3n3g"):
	set = _set_treetop_sprite_frames

@export var trunk_sprite_frames: SpriteFrames = preload("uid://euk5lvoroc5"):
	set = _set_trunk_sprite_frames

@onready var treetop_sprite: AnimatedSprite2D = %TreetopSprite
@onready var trunk_sprite: AnimatedSprite2D = %TrunkSprite


func _set_treetop_sprite_frames(new_treetop_sprite_frames: SpriteFrames) -> void:
	treetop_sprite_frames = new_treetop_sprite_frames
	if not is_node_ready():
		return
	treetop_sprite.sprite_frames = new_treetop_sprite_frames
	if new_treetop_sprite_frames != null:
		treetop_sprite.play(treetop_sprite.animation)


func _set_trunk_sprite_frames(new_trunk_sprite_frames: SpriteFrames) -> void:
	trunk_sprite_frames = new_trunk_sprite_frames
	if not is_node_ready():
		return
	trunk_sprite.sprite_frames = new_trunk_sprite_frames
	if new_trunk_sprite_frames != null:
		trunk_sprite.sprite_frames = new_trunk_sprite_frames
		trunk_sprite.play(trunk_sprite.animation)


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		# Don't randomise scale when editing tree scene itself
		scale = Vector2.ONE

	_set_treetop_sprite_frames(treetop_sprite_frames)
	_set_trunk_sprite_frames(trunk_sprite_frames)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			var y_scale := randf_range(0.8, 1.2)
			var x_scale := y_scale * randf_range(0.9, 1.1)
			scale = Vector2(x_scale, y_scale)
