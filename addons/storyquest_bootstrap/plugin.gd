# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const TOOL_MENU_LABEL := "Create StoryQuest from template..."

const STORYQUESTS_PATH := "res://scenes/quests/story_quests/"
const TEMPLATE_PATH := STORYQUESTS_PATH + "template/"

const NEXT_SCENE_FORMAT = 'next_scene = "%s")'
const NEXT_SCENE_PATTERN = 'next_scene = "(?<next_scene_uid>[^\\s]*")'

static var _next_scene_regex := RegEx.create_from_string(NEXT_SCENE_PATTERN)


func _enter_tree() -> void:
	add_tool_menu_item(TOOL_MENU_LABEL, _new_storyquest_dialogue)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_LABEL)


func _new_storyquest_dialogue() -> void:
	# TODO:
	# - Open a dialogue and ask the title of the new StoryQuest.
	# - Derive a filename from the StoryQuest title, and suggest it as folder name.
	# - Allow editing the folder name, and validate that it's a valid name:
	# -- Check or force snake_case format.
	# -- Check that the path doesn't exist.
	var title := "My quest"
	var description := "This is a test"
	var filename := title.to_snake_case()
	var storyquest_path := STORYQUESTS_PATH + filename
	assert(not FileAccess.file_exists(storyquest_path))
	_new_storyquest_from_template(title, description, storyquest_path)


func _new_storyquest_from_template(
	title: String, description: String, storyquest_path: String
) -> void:
	# TODO: Only for development. Remove.
	OS.execute("rm", ["-r", "scenes/quests/story_quests/my_quest/"])

	var error := DirAccess.make_dir_absolute(storyquest_path)
	assert(error == OK)

	for directory in [
		"/0_template_intro/template_intro_components/",
		"/4_template_outro/template_outro_components/"
	]:
		error = DirAccess.make_dir_recursive_absolute(
			storyquest_path + directory.replacen("template_", "")
		)
		assert(error == OK)

	var template_intro_scene_subpath := "/0_template_intro/template_intro.tscn"
	var intro_scene_subpath := template_intro_scene_subpath.replacen("template_", "")

	var template_outro_scene_subpath := "/4_template_outro/template_outro.tscn"
	var outro_scene_subpath := template_outro_scene_subpath.replacen("template_", "")

	var template_intro_dialogue_subpath := (
		"/0_template_intro/" + "template_intro_components/template_intro.dialogue"
	)
	var intro_dialogue_subpath := template_intro_dialogue_subpath.replacen("template_", "")
	var template_intro_dialogue: DialogueResource = ResourceLoader.load(
		TEMPLATE_PATH + template_intro_dialogue_subpath
	)

	# Saving the raw text because ResourceSaver.save() fails with ERR_FILE_UNRECOGNIZED
	var intro_dialogue_file: FileAccess = FileAccess.open(
		storyquest_path + intro_dialogue_subpath, FileAccess.WRITE
	)
	intro_dialogue_file.store_string(template_intro_dialogue.raw_text)
	intro_dialogue_file.close()

	var template_intro_dialogue_uid := ResourceUID.id_to_text(
		ResourceLoader.get_resource_uid(TEMPLATE_PATH + template_intro_dialogue_subpath)
	)

	EditorInterface.get_resource_filesystem().update_file(storyquest_path + intro_dialogue_subpath)
	EditorInterface.get_resource_filesystem().reimport_files(
		[storyquest_path + intro_dialogue_subpath]
	)

	var intro_dialogue_uid := ResourceUID.id_to_text(
		ResourceLoader.get_resource_uid(storyquest_path + intro_dialogue_subpath)
	)

	var template_intro_scene_uid := ResourceUID.id_to_text(
		ResourceLoader.get_resource_uid(TEMPLATE_PATH + template_intro_scene_subpath)
	)
	var intro_scene_uid: String = ResourceUID.id_to_text(ResourceUID.create_id())

	var template_outro_scene_uid := ResourceUID.id_to_text(
		ResourceLoader.get_resource_uid(TEMPLATE_PATH + template_outro_scene_subpath)
	)
	var outro_scene_uid: String = ResourceUID.id_to_text(ResourceUID.create_id())

	var outro_scene_contents = FileAccess.get_file_as_string(
		TEMPLATE_PATH + template_outro_scene_subpath
	)
	outro_scene_contents = outro_scene_contents.replace(template_outro_scene_uid, outro_scene_uid)
	var outro_scene_file := FileAccess.open(storyquest_path + outro_scene_subpath, FileAccess.WRITE)
	outro_scene_file.store_string(outro_scene_contents)
	outro_scene_file.close()

	var intro_scene_contents = FileAccess.get_file_as_string(
		TEMPLATE_PATH + template_intro_scene_subpath
	)

	intro_scene_contents = intro_scene_contents.replace(template_intro_scene_uid, intro_scene_uid)
	intro_scene_contents = intro_scene_contents.replace(
		template_intro_dialogue_uid, intro_dialogue_uid
	)
	var next_scene_match: RegExMatch = _next_scene_regex.search(intro_scene_contents)
	if next_scene_match:
		intro_scene_contents = _next_scene_regex.sub(
			intro_scene_contents, NEXT_SCENE_FORMAT % outro_scene_uid
		)

	var intro_scene_file := FileAccess.open(storyquest_path + intro_scene_subpath, FileAccess.WRITE)
	intro_scene_file.store_string(intro_scene_contents)
	intro_scene_file.close()

	var storyquest_resource = Storybook.STORY_QUEST_TEMPLATE.duplicate(true)
	storyquest_resource.resource_path = storyquest_path + "/" + Storybook.QUEST_RESOURCE_NAME
	storyquest_resource.title = title
	storyquest_resource.description = description
	storyquest_resource.first_scene = intro_scene_uid
	error = ResourceSaver.save(storyquest_resource)
	assert(error == OK)

	EditorInterface.get_resource_filesystem().scan()
