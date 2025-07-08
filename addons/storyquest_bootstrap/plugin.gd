# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const NEW_STORYQUEST_DIALOG = preload(
	"res://addons/storyquest_bootstrap/new_storyquest_dialog.tscn"
)

const TOOL_MENU_LABEL := "Create StoryQuest from template..."

const STORYQUESTS_PATH := "res://scenes/quests/story_quests/"
# Using + instead of String.path_join() here because it errors with:
# Assigned value for constant "TEMPLATE_PATH" isn't a constant expression.
const TEMPLATE_PATH := STORYQUESTS_PATH + "template/"
const MIN_TITLE_LENGTH := 4

const NEXT_SCENE_FORMAT = 'next_scene = "%s")'
const NEXT_SCENE_PATTERN = 'next_scene = "(?<next_scene_uid>[^\\s]*")'

static var _next_scene_regex := RegEx.create_from_string(NEXT_SCENE_PATTERN)

var template_info := {
	"intro":
	{
		"scene_path": "/0_template_intro/template_intro.tscn",
		"components_path": "/0_template_intro/template_intro_components/",
		"dialogue_path": "/0_template_intro/template_intro_components/template_intro.dialogue",
		"image_path": "0_template_intro/template_intro_components/template_intro_image.png",
	},
	"outro":
	{
		"scene_path": "/4_template_outro/template_outro.tscn",
		"components_path": "/4_template_outro/template_outro_components/",
		"dialogue_path": "/4_template_outro/template_outro_components/template_outro.dialogue",
	}
}

var _new_storyquest_dialog: Window


func _enter_tree() -> void:
	add_tool_menu_item(TOOL_MENU_LABEL, _open_new_storyquest_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_LABEL)


func _open_new_storyquest_dialog() -> void:
	_new_storyquest_dialog = NEW_STORYQUEST_DIALOG.instantiate()
	_new_storyquest_dialog.storyquests_path = STORYQUESTS_PATH
	_new_storyquest_dialog.validate_title = validate_title
	_new_storyquest_dialog.validate_filename = validate_filename
	_new_storyquest_dialog.create_storyquest.connect(_on_create_storyquest)
	_new_storyquest_dialog.close_requested.connect(_close_dialog)
	EditorInterface.popup_dialog(_new_storyquest_dialog)


func _close_dialog() -> void:
	_new_storyquest_dialog.queue_free()
	_new_storyquest_dialog = null


func validate_title(title: String) -> PackedStringArray:
	var errors: PackedStringArray
	if title.length() < MIN_TITLE_LENGTH:
		errors.append("⚠ The title length must be bigger than %d." % MIN_TITLE_LENGTH)
	return errors


func validate_filename(filename: String) -> PackedStringArray:
	var errors: PackedStringArray
	if DirAccess.dir_exists_absolute(STORYQUESTS_PATH.path_join(filename)):
		errors.append(
			"⚠ The StoryQuest folder %s already exists." % STORYQUESTS_PATH.path_join(filename)
		)
	return errors


func _on_create_storyquest(title: String, description: String, filename: String) -> void:
	_close_dialog()

	assert(not validate_title(title).size())
	assert(not validate_filename(filename).size())

	var storyquest_path := STORYQUESTS_PATH.path_join(filename)
	var error := DirAccess.make_dir_absolute(storyquest_path)
	assert(error == OK)

	# These need to be created before the following for loop, because the intro (for instance)
	# needs to replace the outro UID in its content.
	var storyquest_uids := {
		"intro": ResourceUID.id_to_text(ResourceUID.create_id()),
		"outro": ResourceUID.id_to_text(ResourceUID.create_id()),
	}

	for i in template_info:
		var directory: String = template_info[i]["components_path"]
		error = DirAccess.make_dir_recursive_absolute(
			storyquest_path.path_join(directory.replacen("template_", ""))
		)
		assert(error == OK)

		var scene_path: String = template_info[i]["scene_path"].replacen("template_", "")
		var dialogue_path: String = template_info[i]["dialogue_path"].replacen("template_", "")

		var template_dialogue: DialogueResource = ResourceLoader.load(
			TEMPLATE_PATH.path_join(template_info[i]["dialogue_path"])
		)

		# Saving the raw text because ResourceSaver.save() fails with ERR_FILE_UNRECOGNIZED
		var dialogue_file: FileAccess = FileAccess.open(
			storyquest_path.path_join(dialogue_path), FileAccess.WRITE
		)
		dialogue_file.store_string(template_dialogue.raw_text)
		dialogue_file.close()

		var template_dialogue_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(
				TEMPLATE_PATH.path_join(template_info[i]["dialogue_path"])
			)
		)

		var template_scene_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(TEMPLATE_PATH.path_join(template_info[i]["scene_path"]))
		)
		var template_image_uid: String
		var image_path: String
		var template_image_path = template_info[i].get("image_path")
		if template_image_path:
			template_image_uid = ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(TEMPLATE_PATH.path_join(template_image_path))
			)
			# If we use ResourceLoader.load() it brings an CompressedTexture2D from a ctex file.
			# so if we then use resource.duplicate() and try to save it with ResourceSaver.save()
			# to a PNG file, it fails with ERR_FILE_UNRECOGNIZED.
			image_path = storyquest_path.path_join(template_image_path.replacen("template_", ""))
			error = DirAccess.copy_absolute(
				TEMPLATE_PATH.path_join(template_image_path), image_path
			)
			assert(error == OK)

		# The following should be enough instead of a full scan, but it doesn't work:
		# EditorInterface.get_resource_filesystem().update_file(storyquest_path.path_join(dialogue_path))
		# EditorInterface.get_resource_filesystem().reimport_files(
		# 	[storyquest_path.path_join(dialogue_path)]
		# )
		EditorInterface.get_resource_filesystem().scan()
		if EditorInterface.get_resource_filesystem().is_scanning():
			await EditorInterface.get_resource_filesystem().resources_reimported

		var dialogue_uid := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid(storyquest_path.path_join(dialogue_path))
		)

		var image_uid: String
		if image_path:
			image_uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(image_path))

		var scene_contents = FileAccess.get_file_as_string(
			TEMPLATE_PATH.path_join(template_info[i]["scene_path"])
		)

		scene_contents = scene_contents.replace(template_scene_uid, storyquest_uids[i])
		scene_contents = scene_contents.replace(template_dialogue_uid, dialogue_uid)

		if image_uid:
			scene_contents = scene_contents.replace(template_image_uid, image_uid)

		if i == "intro":
			var next_scene_match: RegExMatch = _next_scene_regex.search(scene_contents)
			if next_scene_match:
				scene_contents = _next_scene_regex.sub(
					scene_contents, NEXT_SCENE_FORMAT % storyquest_uids["outro"]
				)

		var scene_file := FileAccess.open(storyquest_path.path_join(scene_path), FileAccess.WRITE)
		scene_file.store_string(scene_contents)
		scene_file.close()

	var storyquest_resource = Storybook.STORY_QUEST_TEMPLATE.duplicate(true)
	storyquest_resource.resource_path = storyquest_path.path_join(Storybook.QUEST_RESOURCE_NAME)
	storyquest_resource.title = title
	storyquest_resource.description = description
	storyquest_resource.first_scene = storyquest_uids["intro"]
	error = ResourceSaver.save(storyquest_resource)
	assert(error == OK)

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.select_file(storyquest_path)
