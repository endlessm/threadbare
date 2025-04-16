# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var spool_texture: Texture2D = preload(
	"res://scenes/game_elements/props/decoration/spool/components/ThreadSpool1.png"
):
	set(new_texture):
		spool_texture = new_texture
		if spool_sprite:
			spool_sprite.texture = spool_texture

@onready var spool_sprite: Sprite2D = $SpoolSprite


func _ready() -> void:
	spool_sprite.texture = spool_texture
