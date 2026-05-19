# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name RandomTextureSpriteBehavior
extends BaseSpriteBehavior
## @experimental
##
## Can set a random texture to a sprite.
##
## The idle texture filename may have offset information. In that case,
## also set the position of each sub-sprite in the controlled sprite children.

const SpriteFramesHelper = preload(
	"res://addons/sprite_frames_exported_textures/sprite_frames_helper.gd"
)

## The array of spriteframes, from which to pick a random one.
@export var sprite_frames: Array[SpriteFrames]

## Click this button to set a random texture to the sprite.
@export_tool_button("Randomize") var randomize_texture_button: Callable = randomize_texture


func _get_offset_from_spriteframes_filename(new_sprite_frames: SpriteFrames) -> Vector2:
	var filename: String
	var sprite_frame_filename := new_sprite_frames.resource_path.get_file()
	if sprite_frame_filename:
		filename = sprite_frame_filename
	elif "idle" in new_sprite_frames.get_animation_names():
		var idle_texture := new_sprite_frames.get_frame_texture(&"idle", 0)
		if idle_texture is AtlasTexture:
			idle_texture = idle_texture.atlas
		filename = idle_texture.resource_path.get_file()

	var offset := Vector2.ZERO
	if not filename:
		push_warning("%s: Can't find filename for %s" % [get_path(), new_sprite_frames])
		return offset

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
func randomize_texture(rng: RandomNumberGenerator = null) -> void:
	var random_int: int = rng.randi() if rng else randi()
	var index := random_int % sprite_frames.size()
	var new_sprite_frames := sprite_frames[index]

	var offset := _get_offset_from_spriteframes_filename(new_sprite_frames)
	_offset_child_sprites(offset)

	var previous_animation := sprite.animation
	sprite.sprite_frames = new_sprite_frames
	if not Engine.is_editor_hint():
		if previous_animation in sprite.sprite_frames.get_animation_names():
			sprite.play(previous_animation)
			sprite.set_frame_and_progress(0, 0.0)
