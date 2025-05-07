# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name FillingBarrel
extends StaticBody2D

signal completed

const NEEDED: int = 3
const DEFAULT_TEXTURE: Texture2D = preload("uid://b2nmajpf8dlh")

## Projectiles with this label fill the barrel.
@export var label: String = "???"

## Optional color to tint the barrel.
@export var color: Color:
	set = _set_color

## Optional custom texture for the barrel. An inkwell texture is used by default.
## The texture must have 4 vertical frames, from empty to filled.
@export var texture: Texture2D:
	set = _set_texture

var _amount: int = 0

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var hit_box: StaticBody2D = %HitBox


func _set_color(new_color: Color) -> void:
	color = new_color
	if not is_node_ready():
		return
	if color:
		sprite_2d.modulate = color
	else:
		sprite_2d.modulate = Color.WHITE


func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	if not is_node_ready():
		return
	if texture:
		sprite_2d.texture = texture
	else:
		sprite_2d.texture = DEFAULT_TEXTURE


func _ready() -> void:
	_set_color(color)
	_set_texture(texture)


## Increment the amount by one and play the fill animation. If completed, also play the completed
## animation and remove this barrel from the current scene.
func fill() -> void:
	if _amount >= NEEDED:
		return
	animation_player.play(&"fill")
	_amount += 1
	sprite_2d.frame += 1
	if _amount >= NEEDED:
		_disable_collisions.call_deferred()
		await animation_player.animation_finished
		animation_player.play(&"completed")
		await animation_player.animation_finished
		queue_free()
		completed.emit()


func _disable_collisions() -> void:
	hit_box.process_mode = Node.PROCESS_MODE_DISABLED
	collision_shape_2d.disabled = true
