# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Decoration_el_abrigo
extends Node2D

@export var texture: Texture2D:
	set = _set_texture

@export var flip_h: bool:
	set = _set_flip_h

@export var flip_v: bool:
	set = _set_flip_v

@export var offset: Vector2:
	set = _set_offset

@export_category("Collision")
@export var enable_collision: bool = true

@onready var sprite_2d: Sprite2D = %Sprite2D


func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_node_ready():
		return
	if texture != null:
		sprite_2d.texture = texture


func _set_flip_h(new_flip_h: bool) -> void:
	flip_h = new_flip_h
	if not is_node_ready():
		return
	sprite_2d.flip_h = flip_h


func _set_flip_v(new_flip_v: bool) -> void:
	flip_v = new_flip_v
	if not is_node_ready():
		return
	sprite_2d.flip_v = flip_v


func _set_offset(new_offset: Vector2) -> void:
	offset = new_offset
	if not is_node_ready():
		return
	sprite_2d.offset = offset


func _ready() -> void:
	_set_texture(texture)
	_set_flip_h(flip_h)
	_set_flip_v(flip_v)
	_set_offset(offset)
	
	if enable_collision and not Engine.is_editor_hint():
		_setup_collision()


func _setup_collision() -> void:
	var collision_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = Vector2(100, 110)
	collision_area.position = Vector2(0, -25)
	collision_shape.shape = rectangle_shape
	collision_area.add_child(collision_shape)
	add_child(collision_area)
	
	
	collision_area.connect("body_entered", _on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("¡Jugador chocó con el objeto decorativo!")
		
		if body.has_method("volver_al_inicio"):
			body.volver_al_inicio()
