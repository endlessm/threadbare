# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends AnimatedSprite2D

@export_tool_button("Print Textures") var _textures_used = print_base_textures_used

@onready var player: Player = owner


func _get_property_list() -> Array:
	var textures_category = {
		"name": "Textures",
		"usage": PROPERTY_USAGE_GROUP,
		"type": TYPE_NIL,
		"hint_string": "_textures"
	}
	var textures_properties = base_textures_used().map(
		func(texture: Texture2D):
			return {
				"name": "_textures_" + texture.resource_path.get_file().get_basename(),
				"type": TYPE_OBJECT,
				"hint_string": "Texture2D"
			}
	)
	return [textures_category] + textures_properties


func _get(property: StringName):
	if property.begins_with("_textures_"):
		var texture_filename = property.trim_prefix("_textures_")
		for texture in base_textures_used():
			if texture.resource_path.get_file().get_basename() == texture_filename:
				return texture
	return null


func _set(property: StringName, value: Variant):
	if property.begins_with("_textures_"):
		var old_base_texture: Texture2D = get(property)
		var new_texture := value as Texture2D
		if old_base_texture and old_base_texture.get_size() != new_texture.get_size():
			if old_base_texture.get_size() != new_texture.get_size():
				var error_message = (
					"New texture's size (%dx%d) doesn't match old texture's size (%dx%d)"
					% [
						#new_texture.resource_path,
						new_texture.get_width(),
						new_texture.get_height(),
						#old_base_texture.resource_path,
						old_base_texture.get_width(),
						old_base_texture.get_height(),
					]
				)
				EditorInterface.get_editor_toaster().push_toast(
					error_message, EditorToaster.SEVERITY_ERROR
				)
				#push_error(error_message)
				return
		for animation_name in sprite_frames.get_animation_names():
			var sprite_frame_count = sprite_frames.get_frame_count(animation_name)

			for sprite_frame_idx in sprite_frame_count:
				var texture: Texture2D = sprite_frames.get_frame_texture(
					animation_name, sprite_frame_idx
				)
				if old_base_texture == get_base_texture(sprite_frames, texture):
					replace_base_texture(
						sprite_frames, animation_name, sprite_frame_idx, texture, value
					)

		var sprite_frames_editor = (
			Engine
			. get_singleton("EditorInterface")
			. get_base_control()
			. find_children("", "SpriteFramesEditor", true, false)
			. front()
		)
		if sprite_frames_editor:
			sprite_frames_editor.hide()
			sprite_frames_editor.show()
		notify_property_list_changed()
		return true

	return false


func base_textures_used():
	var textures = []
	for animation_name in sprite_frames.get_animation_names():
		var sprite_frame_count = sprite_frames.get_frame_count(animation_name)

		for sprite_frame_idx in sprite_frame_count:
			var texture: Texture2D = sprite_frames.get_frame_texture(
				animation_name, sprite_frame_idx
			)
			var base_texture: Texture2D = get_base_texture(sprite_frames, texture)

			if base_texture and not base_texture in textures:
				textures.push_back(base_texture)

	return textures


func print_base_textures_used():
	print(base_textures_used())


func replace_base_texture(
	frames: SpriteFrames,
	anim_name: StringName,
	sprite_frame_idx: int,
	old_texture: Texture2D,
	new_texture: Texture2D
):
	var is_saved_in_sprite_frame_resource: bool = old_texture.resource_path.begins_with(
		frames.resource_path
	)
	var old_base_texture = get_base_texture(frames, old_texture)

	if not is_saved_in_sprite_frame_resource:
		var frame_duration = frames.get_frame_duration(anim_name, sprite_frame_idx)
		frames.set_frame(anim_name, sprite_frame_idx, new_texture, frame_duration)
		return

	if old_texture is AtlasTexture:
		old_texture.atlas = new_texture


func get_base_texture(frames: SpriteFrames, texture: Texture2D) -> Texture2D:
	var is_saved_in_sprite_frame_resource: bool = texture.resource_path.begins_with(
		frames.resource_path
	)

	if not is_saved_in_sprite_frame_resource:
		return texture

	if texture is AtlasTexture:
		return get_base_texture(frames, texture.atlas)

	return null


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not player:
		return
	if player.velocity.is_zero_approx():
		return
	if not is_zero_approx(player.velocity.x):
		flip_h = player.velocity.x < 0


func look_at_side(side: Enums.LookAtSide) -> void:
	if side == 0:
		return
	flip_h = side < 0
