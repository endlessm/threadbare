# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Quest
extends Resource
## Information that defines a playable quest

## The quest's title. This should be short, like the title of a novel.
@export var title: String:
	set(new_value):
		title = new_value.strip_edges()

## A short description of the quest. This should be a single paragraph of around 2–3 sentences.
@export_multiline var description: String

## The names of the people who created this quest: artists, writers, designers, developers, etc.
@export var authors: Array[String]

## Optional affiliation of the authors, such as a university, game jam, or community group.
## Leave blank if not needed.
@export var affiliation: String

@export_group("Advanced")

## The path to the first scene of the quest. If you are following the structure of the template,
## leave this as the default path. The path can be absolute (beginning with [code]res://[/code])
## or relative to the folder where this quest resource is saved.
@export_file("*.tscn") var first_scene: String = "0_intro/intro.tscn"


func _to_string() -> String:
	return '<Quest %s: "%s">' % [resource_path]


## Returns [member title] if set, or a placeholder identifying the quest otherwise.
func get_title() -> String:
	if title:
		return title

	return resource_path.get_base_dir().get_file()


## Resolves [member first_scene] relative to the directory this Quest is stored in, if necessary.
func get_first_scene_path() -> String:
	if first_scene.is_absolute_path():
		return first_scene

	return resource_path.get_base_dir().path_join(first_scene)
