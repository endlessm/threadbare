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
		errors.append("⚠ The title must be at least %d letters long." % MIN_TITLE_LENGTH)
	return errors


func validate_filename(filename: String) -> PackedStringArray:
	var errors: PackedStringArray
	if not filename:
		errors.append("⚠ The StoryQuest folder name cannot be empty.")
	else:
		var target := STORYQUESTS_PATH.path_join(filename)
		if DirAccess.dir_exists_absolute(target):
			errors.append("⚠ The StoryQuest folder %s already exists." % target)
	return errors


func _on_create_storyquest(title: String, description: String, filename: String) -> void:
	_close_dialog()

	assert(not validate_title(title).size())
	assert(not validate_filename(filename).size())

	var storyquest_path := STORYQUESTS_PATH.path_join(filename)
	var error := DirAccess.make_dir_absolute(storyquest_path)
	assert(error == OK)

	var intro_scene_path: String

	for i in template_info:
		var directory: String = template_info[i]["components_path"]
		error = DirAccess.make_dir_recursive_absolute(
			storyquest_path.path_join(directory.replacen("template_", ""))
		)
		assert(error == OK)

		var dialogue_path: String = template_info[i]["dialogue_path"].replacen("template_", "")

		var template_dialogue: DialogueResource = ResourceLoader.load(
			TEMPLATE_PATH.path_join(template_info[i]["dialogue_path"])
		)

		# Duplicating the file because ResourceSaver.save() fails with ERR_FILE_UNRECOGNIZED
		error = DirAccess.copy_absolute(
			TEMPLATE_PATH.path_join(template_info[i]["dialogue_path"]),
			storyquest_path.path_join(dialogue_path)
		)
		assert(error == OK)

		var image_path: String
		var template_image_path = template_info[i].get("image_path")
		if template_image_path:
			# If we use ResourceLoader.load() it brings an CompressedTexture2D from a ctex file.
			# so if we then use resource.duplicate() and try to save it with ResourceSaver.save()
			# to a PNG file, it fails with ERR_FILE_UNRECOGNIZED.
			image_path = storyquest_path.path_join(template_image_path.replacen("template_", ""))
			error = DirAccess.copy_absolute(
				TEMPLATE_PATH.path_join(template_image_path), image_path
			)
			assert(error == OK)

		# The following should be enough instead of a full scan, but it doesn't work.
		#
		# for f in files_to_reimport:
		# 	EditorInterface.get_resource_filesystem().update_file(f)
		# EditorInterface.get_resource_filesystem().reimport_files(files_to_reimport)
		#
		# Where files_to_reimport contains the paths of files copied with DirAccess.copy_absolute()
		EditorInterface.get_resource_filesystem().scan()
		if EditorInterface.get_resource_filesystem().is_scanning():
			await EditorInterface.get_resource_filesystem().resources_reimported

		var dialogue: DialogueResource = ResourceLoader.load(
			storyquest_path.path_join(dialogue_path)
		)

		var template_scene := load(TEMPLATE_PATH.path_join(template_info[i]["scene_path"]))
		var packed_scene: PackedScene = template_scene.duplicate(true)
		var scene_path := storyquest_path.path_join(
			template_info[i]["scene_path"].replacen("template_", "")
		)
		if i == "intro":
			intro_scene_path = scene_path
		var scene := packed_scene.instantiate()
		var cinematic_node := scene.get_node_or_null("Cinematic")
		assert(cinematic_node != null)
		cinematic_node.set("dialogue", dialogue)
		if i == "intro":
			var outro_scene_path := storyquest_path.path_join(
				template_info["outro"]["scene_path"].replacen("template_", "")
			)
			cinematic_node.set("next_scene", outro_scene_path)

		if image_path:
			var image_node := scene.get_node_or_null("TileMapLayers/IntroImage")
			assert(image_node != null)
			var image := ResourceLoader.load(image_path)
			image_node.set("texture", image)

		error = packed_scene.pack(scene)
		assert(error == OK)

		error = ResourceSaver.save(packed_scene, scene_path)
		assert(error == OK)

	var storyquest_resource := Storybook.STORY_QUEST_TEMPLATE.duplicate(true)
	var intro_uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(intro_scene_path))
	storyquest_resource.resource_path = storyquest_path.path_join(Storybook.QUEST_RESOURCE_NAME)
	storyquest_resource.title = title
	storyquest_resource.description = description
	storyquest_resource.first_scene = intro_uid
	error = ResourceSaver.save(storyquest_resource)
	assert(error == OK)

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.select_file(storyquest_path)
