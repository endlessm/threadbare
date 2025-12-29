# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RandomTextureSpriteBehavior
extends BaseSpriteBehavior
## @experimental
##
## Can set a random texture to a sprite.
##
## The picked texture may have offset information. In that case,
## also set the position of each sub-sprite in the controlled sprite children.

const SpriteFramesHelper = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_helper.gd"
)

## The array of textures, from which to pick a random one.
@export var textures: Array[Texture2D]

## Click this button to set a random texture to the sprite.
@export_tool_button("Randomize") var randomize_texture_button: Callable = randomize_texture


func _get_offset_from_texture_filename(new_texture: Texture2D) -> Vector2:
	var filename: String = new_texture.resource_path.get_file()
	var offset := Vector2.ZERO
	# TODO: Use regular expressions.
	for part: String in filename.split("."):
		var data := part.split("_")
		if data.size() != 2:
			continue
		var k := data[0]
		var v := data[1]
		if k == "dx" and v.is_valid_int():
			offset.x += v.to_int()
		elif k == "dy" and v.is_valid_int():
			offset.y += v.to_int()
	return offset


func _offset_child_sprites(offset: Vector2) -> void:
	for child in sprite.get_children():
		if child is AnimatedSprite2D:
			(child as AnimatedSprite2D).position = offset


## Pick a random texture from [member textures] and set it to the sprite.
func randomize_texture() -> void:
	var new_texture: Texture2D = textures.pick_random()
	var offset := _get_offset_from_texture_filename(new_texture)
	_offset_child_sprites(offset)
	SpriteFramesHelper.replace_texture(null, new_texture, sprite.sprite_frames)
