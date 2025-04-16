# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node2D

@export var bush_texture: Texture2D = preload(
	"res://scenes/game_elements/props/decoration/bush/components/Bush1.png"
):
	set(new_texture):
		bush_texture = new_texture
		if bush_sprite:
			bush_sprite.texture = bush_texture

@onready var bush_sprite: Sprite2D = $BushSprite


func _ready() -> void:
	bush_sprite.texture = bush_texture
