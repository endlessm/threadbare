# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Character
extends CharacterBody2D

@export var character_name: String = ""

@export var animated_sprite_2d: AnimatedSprite2D:
	set = _set_animated_sprite_2d

@export var look_at_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED:
	set = _set_look_at_side


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	if Engine.is_editor_hint():
		return
	_set_animated_sprite_2d(animated_sprite_2d)
	_set_look_at_side(look_at_side)


func _set_animated_sprite_2d(new_animated_sprite_2d: AnimatedSprite2D) -> void:
	animated_sprite_2d = new_animated_sprite_2d


func _set_look_at_side(new_look_at_side: Enums.LookAtSide) -> void:
	look_at_side = new_look_at_side
	if not is_node_ready():
		return
	if animated_sprite_2d:
		animated_sprite_2d.flip_h = look_at_side == Enums.LookAtSide.LEFT


func _on_child_entered_tree(node: Node) -> void:
	if node is AnimatedSprite2D and not animated_sprite_2d:
		animated_sprite_2d = node
