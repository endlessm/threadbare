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

## [Quest] resources must have this filename to be found by the game.
const FILENAME := "quest.tres"

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

## The number of threads that the player collects in this quest - typically one
## at the end of each mini-game/challenge. This should match the number of
## [CollectibleItem]s in the quest.
@export_range(0, 6, 1, "suffix:threads") var threads_to_collect: int = 3

@export_group("Animation")

## An optional sprite frame library to show in the storybook page for this quest.
## This could be the main character, an NPC, or an important item in the quest.
@export var sprite_frames: SpriteFrames:
	set(new_value):
		sprite_frames = new_value
		notify_property_list_changed()

## The animation in [member sprite_frames] to display. This should typically be a looping animation.
@export var animation_name: StringName = &""


## Lists all quests in [param quest_directory]; which is to say, all [Quest]
## resources named [const FILENAME] which are in an immediate subdirectory of
## [param quest_directory].
## [br][br]
## In Bash terms, this is: [code]$quest_directory/*/quest.tres[/code]
static func enumerate(quest_directory: String) -> Array[Quest]:
	var quests: Array[Quest] = []

	for dir in ResourceLoader.list_directory(quest_directory):
		var quest_path := quest_directory.path_join(dir).path_join(FILENAME)
		if ResourceLoader.exists(quest_path):
			var quest: Quest = ResourceLoader.load(quest_path)
			quests.append(quest)

	return quests


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
