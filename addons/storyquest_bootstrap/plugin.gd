# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const NEW_STORYQUEST_DIALOG = preload(
	"res://addons/storyquest_bootstrap/new_storyquest_dialog.tscn"
)
const Copier = preload("./copier.gd")

const TOOL_MENU_LABEL := "Create StoryQuest from template..."

const MIN_TITLE_LENGTH := 4

var _new_storyquest_dialog: Window


func _enter_tree() -> void:
	add_tool_menu_item(TOOL_MENU_LABEL, _open_new_storyquest_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_LABEL)


func _open_new_storyquest_dialog() -> void:
	_new_storyquest_dialog = NEW_STORYQUEST_DIALOG.instantiate()
	_new_storyquest_dialog.storyquests_path = Copier.STORYQUESTS_PATH
	_new_storyquest_dialog.validate_title = validate_title
	_new_storyquest_dialog.validate_filename = validate_filename
	_new_storyquest_dialog.create_storyquest.connect(_on_create_storyquest)
	_new_storyquest_dialog.cancel.connect(_close_dialog)
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
		var target: String = Copier.STORYQUESTS_PATH.path_join(filename)
		if DirAccess.dir_exists_absolute(target):
			errors.append("⚠ The StoryQuest folder %s already exists." % target)
	return errors


func _on_create_storyquest(title: String, description: String, filename: String) -> void:
	assert(not validate_title(title).size())
	assert(not validate_filename(filename).size())

	var copier: Copier = Copier.new(filename, title, description)
	await copier.create_storyquest()
	_close_dialog()

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.select_file(copier.target_path)
