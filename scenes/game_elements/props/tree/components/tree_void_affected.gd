# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

enum TreetopVariant { GREEN, BLUE, PURPLE, RED, YELLOW }

const TREETOP_SPRITEFRAMES_PER_VARIANT: Dictionary[TreetopVariant, SpriteFrames] = {
	TreetopVariant.GREEN: preload("uid://d2i5boaxe3n3g"),
	TreetopVariant.BLUE: preload("uid://cthoo4vcj8la3"),
	TreetopVariant.PURPLE: preload("uid://babag0ug8ur4d"),
	TreetopVariant.RED: preload("uid://f5v8kvfopaxt"),
	TreetopVariant.YELLOW: preload("uid://pw7ol6ry6wvi"),
}

const TRUNK_SPRITEFRAMES_PER_VARIANT: Dictionary[int, SpriteFrames] = {
	0: preload("uid://e0qx3m0561sr"),
	1: preload("uid://euk5lvoroc5"),
	2: preload("uid://i1u6og25swna"),
}

@export var treetop_variant: TreetopVariant = TreetopVariant.GREEN:
	set = _set_treetop_variant

@export_range(0, 2) var trunk_variant: int = 0:
	set = _set_trunk_variant

@onready var treetop_sprite: AnimatedSprite2D = %TreetopSprite
@onready var trunk_sprite: AnimatedSprite2D = %TrunkSprite


func _set_treetop_variant(new_treetop_variant: TreetopVariant) -> void:
	treetop_variant = new_treetop_variant
	if not is_node_ready():
		return
	treetop_sprite.sprite_frames = TREETOP_SPRITEFRAMES_PER_VARIANT[treetop_variant]
	treetop_sprite.play(treetop_sprite.animation)


func _set_trunk_variant(new_trunk_variant: int) -> void:
	trunk_variant = new_trunk_variant
	if not is_node_ready():
		return
	trunk_sprite.sprite_frames = TRUNK_SPRITEFRAMES_PER_VARIANT[trunk_variant]
	trunk_sprite.play(trunk_sprite.animation)


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		# Don't randomise scale when editing tree scene itself
		scale = Vector2.ONE

	_set_treetop_variant(treetop_variant)
	_set_trunk_variant(trunk_variant)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			var y_scale := randf_range(0.8, 1.2)
			var x_scale := y_scale * randf_range(0.9, 1.1)
			scale = Vector2(x_scale, y_scale)
