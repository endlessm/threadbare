class_name Altar
extends Node2D

@export var clean_texture: Texture2D
@export var corrupted_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func set_corrupted(value: bool) -> void:

	if value:
		sprite.texture = corrupted_texture
	else:
		sprite.texture = clean_texture
