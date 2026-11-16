# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Quest
extends Resource
## Information that defines a playable quest

## The development status of a quest.
enum Status {
	## The quest is still being developed. It is playable but incomplete.
	WORK_IN_PROGRESS = 0,
	## The quest has been fully implemented and is ready for all players to play.
	COMPLETE = 1,
	## The quest is actively broken. If played, it may be unwinnable, may crash, etc.
	BROKEN = 2,
}

## The development status of this quest.
@export var status: Status = Status.WORK_IN_PROGRESS

## The quest's title. This should be short, like the title of a novel.
@export var title: String

## A short description of the quest. This should be a single paragraph of around 2–3 sentences.
@export_multiline var description: String

## The names of the people who created this quest: artists, writers, designers, developers, etc.
@export var authors: Array[String]

## Optional affiliation of the authors, such as a university, game jam, or community group.
## Leave blank if not needed.
@export var affiliation: String

## The path to the first scene of the quest.
@export_file("*.tscn") var first_scene: String

@export_group("Animation")

## An optional sprite frame library to show in the storybook page for this quest.
## This could be the main character, an NPC, or an important item in the quest.
@export var sprite_frames: SpriteFrames:
	set(new_value):
		sprite_frames = new_value
		notify_property_list_changed()

## The animation in [member sprite_frames] to display. This should typically be a looping animation.
@export var animation_name: StringName = &""


func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"animation_name":
			if sprite_frames:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(sprite_frames.get_animation_names())
			else:
				property.usage |= PROPERTY_USAGE_READ_ONLY


func _to_string() -> String:
	return '<Quest %s: "%s">' % [resource_path, title]


## Returns [member title] if set, or a placeholder identifying the quest otherwise.
func get_title() -> String:
	if title:
		return title

	return resource_path.get_base_dir().get_file()
