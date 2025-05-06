extends Node


static func base_textures_used(sprite_frames: SpriteFrames) -> Array:
	var textures = []
	for animation_name in sprite_frames.get_animation_names():
		var sprite_frame_count = sprite_frames.get_frame_count(animation_name)

		for sprite_frame_idx in sprite_frame_count:
			var texture: Texture2D = sprite_frames.get_frame_texture(
				animation_name, sprite_frame_idx
			)
			var base_texture: Texture2D = _get_base_texture(sprite_frames, texture)

			if base_texture and not base_texture in textures:
				textures.push_back(base_texture)

	return textures


static func _get_base_texture(frames: SpriteFrames, texture: Texture2D) -> Texture2D:
	var is_included_in_other_resource: bool = not FileAccess.file_exists(texture.resource_path)

	if not is_included_in_other_resource:
		return texture

	if texture is AtlasTexture:
		return _get_base_texture(frames, texture.atlas)

	return null


static func replace_texture(
	old_base_texture: Texture2D, new_texture: Texture2D, sprite_frames: SpriteFrames
) -> void:
	for animation_name in sprite_frames.get_animation_names():
		var sprite_frame_count = sprite_frames.get_frame_count(animation_name)

		for sprite_frame_idx in sprite_frame_count:
			var texture: Texture2D = sprite_frames.get_frame_texture(
				animation_name, sprite_frame_idx
			)
			if old_base_texture == _get_base_texture(sprite_frames, texture):
				_replace_base_texture(
					sprite_frames, animation_name, sprite_frame_idx, texture, new_texture
				)


static func _replace_base_texture(
	frames: SpriteFrames,
	anim_name: StringName,
	sprite_frame_idx: int,
	old_texture: Texture2D,
	new_texture: Texture2D
) -> void:
	var is_included_in_other_resource: bool = not FileAccess.file_exists(old_texture.resource_path)
	var old_base_texture = _get_base_texture(frames, old_texture)

	if not is_included_in_other_resource:
		var frame_duration = frames.get_frame_duration(anim_name, sprite_frame_idx)
		frames.set_frame(anim_name, sprite_frame_idx, new_texture, frame_duration)
		return

	if old_texture is AtlasTexture:
		var new_atlas_texture = old_texture.duplicate(true)
		new_atlas_texture.atlas = new_texture
		var frame_duration = frames.get_frame_duration(anim_name, sprite_frame_idx)
		frames.set_frame(anim_name, sprite_frame_idx, new_atlas_texture, frame_duration)

	if frames.resource_path:
		ResourceSaver.save(frames)
