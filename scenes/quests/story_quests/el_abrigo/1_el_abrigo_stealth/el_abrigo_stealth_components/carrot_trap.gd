# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://dm5jcge3jb7p1")

@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_category("Collision")
@export var enable_reset_collision: bool = true

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	animated_sprite_2d.sprite_frames = new_sprite_frames
	animated_sprite_2d.play(animated_sprite_2d.animation)


func _ready() -> void:
	_set_sprite_frames(sprite_frames)
	
	if enable_reset_collision and not Engine.is_editor_hint():
		_setup_reset_collision()

func _setup_reset_collision() -> void:
	var collision_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = Vector2(20, 20)  
	
	collision_shape.shape = rectangle_shape
	collision_area.add_child(collision_shape)
	add_child(collision_area)
	
	if animated_sprite_2d:
		collision_area.position = animated_sprite_2d.position
	
	collision_area.connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("¡Jugador chocó con el objeto!")
		
		if body.has_method("volver_al_inicio"):
			body.volver_al_inicio()
