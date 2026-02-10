# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name AnimatedTextureRect
extends TextureRect
## A [TextureRect] which shows a single animation from a [SpriteFrames].
##
## This is useful because the only built-in way to display an animation in a
## TextureRect is to use an [AnimatedTexture], which is documented to be
## deprecated and broken; and because we use this to display an animation from
## an in-game sprite, so an appropriate SpriteFrames will already exist.

## A sprite frame library containing the animation. If unset, no texture is shown.
@export var sprite_frames: SpriteFrames:
	set(new_value):
		sprite_frames = new_value
		notify_property_list_changed()
		update_configuration_warnings()
		if is_node_ready():
			_restart()

## The animation from [member sprite_frames] to display. If this animation is
## not defined in [member sprite_frames], no texture is shown.
@export var animation_name: StringName = &"idle":
	set(new_value):
		animation_name = new_value
		update_configuration_warnings()
		if is_node_ready():
			_restart()

@export_tool_button("Restart Animation") var restart_animation := _restart

var _frame: int = 0
var _time_to_next_frame: float = 0.0


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"animation_name":
			if sprite_frames:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(sprite_frames.get_animation_names())
			else:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if sprite_frames and sprite_frames.get_animation_names().find(animation_name) == -1:
		warnings.append("Sprite Frames does not define '%s' animation" % animation_name)

	return warnings


func _ready() -> void:
	_restart()


func _update_texture() -> void:
	texture = sprite_frames.get_frame_texture(animation_name, _frame)


func _extend_next_frame_time() -> void:
	_time_to_next_frame += (
		sprite_frames.get_frame_duration(animation_name, _frame)
		/ sprite_frames.get_animation_speed(animation_name)
	)


func _restart() -> void:
	if (
		not sprite_frames
		or not sprite_frames.has_animation(animation_name)
		or not sprite_frames.get_frame_count(animation_name)
	):
		texture = null
		set_process(false)
		return

	_frame = 0
	_time_to_next_frame = 0
	_update_texture()
	_extend_next_frame_time()
	set_process(true)


func _process(delta: float) -> void:
	if not sprite_frames or not sprite_frames.has_animation(animation_name):
		return

	# It is unlikely but possible that an animation frame's duration may be so
	# short that it should be skipped entirely.
	_time_to_next_frame -= delta
	while _time_to_next_frame < 0:
		if _frame + 1 < sprite_frames.get_frame_count(animation_name):
			_frame += 1
		elif sprite_frames.get_animation_loop(animation_name):
			_frame = 0
		else:
			# Animation finished
			set_process(false)
			break

		_extend_next_frame_time()

	# Only update texture once, potentially after skipping 1 or more frames
	_update_texture()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			# Don't persist whatever frame of the animation happens to be
			# currently shown when saving the scene.
			texture = null
			set_process(false)

		NOTIFICATION_EDITOR_POST_SAVE:
			_restart()
