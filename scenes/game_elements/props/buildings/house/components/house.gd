# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var house_texture: Texture2D = preload("./House_Patch_Blue_01.png"):
	set(new_texture):
		house_texture = new_texture
		if house_sprite:
			house_sprite.texture = house_texture

@onready var house_sprite: Sprite2D = %HouseSprite


func _ready() -> void:
	house_sprite.texture = house_texture
