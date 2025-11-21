# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name farmertrap
extends CharacterBody2D

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://cpm5o35ede3qs")

@export var npc_name: String

@export var look_at_side: Enums.LookAtSide = Enums.LookAtSide.LEFT:
	set = _set_look_at_side

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_category("Collision")
@export var enable_reset_collision: bool = true

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_look_at_side(new_look_at_side: Enums.LookAtSide) -> void:
	look_at_side = new_look_at_side
	if not is_node_ready():
		return
	animated_sprite_2d.flip_h = look_at_side == Enums.LookAtSide.LEFT


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
	
	if enable_reset_collision and not Engine.is_editor_hint():
		_setup_reset_collision()


func _setup_reset_collision() -> void:
	var collision_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = Vector2(40, 50)  
	
	collision_shape.shape = rectangle_shape
	collision_area.add_child(collision_shape)
	add_child(collision_area)
	
	collision_area.connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("💥 Jugador chocó con la roca, reiniciando nivel...")
		
		if body.has_method("defeat"):
			body.defeat()
