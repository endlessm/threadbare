# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const NEW_STORYQUEST_DIALOG = preload(
	"res://addons/storyquest_bootstrap/new_storyquest_dialog.tscn"
)
const Copier = preload("./copier.gd")

const COMMAND_PALETTE_KEY := "plugins/storyquest_bootstrap/blahblah"

## Translation domain for this addon. Because its text is translated in the locale of the editor
## rather than the game locale.
const TRANSLATION_DOMAIN := &"storyquest_bootstrap"

## Project setting listing the translation catalogs of the game.
const TRANSLATIONS_SETTING := "internationalization/locale/translations"

const MIN_TITLE_LENGTH := 4

## Localized label for the menu entry.
var _tool_menu_label: String
var _new_storyquest_dialog: Window


func _enter_tree() -> void:
	_setup_translation_domain()
	set_translation_domain(TRANSLATION_DOMAIN)

	_tool_menu_label = tr("Create StoryQuest from template...")
	add_tool_menu_item(_tool_menu_label, _open_new_storyquest_dialog)
	EditorInterface.get_command_palette().add_command(
		_tool_menu_label, COMMAND_PALETTE_KEY, _open_new_storyquest_dialog
	)


func _exit_tree() -> void:
	remove_tool_menu_item(_tool_menu_label)
	EditorInterface.get_command_palette().remove_command(COMMAND_PALETTE_KEY)
	TranslationServer.remove_domain(TRANSLATION_DOMAIN)


## Fills [constant TRANSLATION_DOMAIN] with the catalog of the project, and changes the locale
## to the one currently set in the editor.
## [br][br]
## It uses the same catalog as the game for simplicity, and because this addon is not meant to be
## reusable in other projects.
static func _setup_translation_domain() -> void:
	var domain := TranslationServer.get_or_add_domain(TRANSLATION_DOMAIN)

	domain.clear()
	domain.set_locale_override(TranslationServer.get_tool_locale())

	for path: String in ProjectSettings.get_setting(TRANSLATIONS_SETTING, PackedStringArray()):
		var translation := ResourceLoader.load(path) as Translation
		if translation:
			domain.add_translation(translation)


func _open_new_storyquest_dialog() -> void:
	_new_storyquest_dialog = NEW_STORYQUEST_DIALOG.instantiate()
	_new_storyquest_dialog.set_translation_domain(TRANSLATION_DOMAIN)
	_new_storyquest_dialog.storyquests_path = Copier.STORYQUESTS_PATH
	_new_storyquest_dialog.validate_title = validate_title
	_new_storyquest_dialog.validate_filename = validate_filename
	_new_storyquest_dialog.create_storyquest.connect(_on_create_storyquest)
	_new_storyquest_dialog.cancel.connect(_close_dialog)
	_new_storyquest_dialog.size *= EditorInterface.get_editor_scale()
	EditorInterface.popup_dialog_centered(_new_storyquest_dialog)


func _close_dialog() -> void:
	_new_storyquest_dialog.queue_free()
	_new_storyquest_dialog = null


func validate_title(title: String) -> PackedStringArray:
	var errors: PackedStringArray
	if title.length() < MIN_TITLE_LENGTH:
		errors.append(tr("⚠ The title must be at least %d letters long.") % MIN_TITLE_LENGTH)
	return errors


func validate_filename(filename: String) -> PackedStringArray:
	var errors: PackedStringArray
	if not filename:
		errors.append(tr("⚠ The StoryQuest folder name cannot be empty."))
	else:
		var target: String = Copier.STORYQUESTS_PATH.path_join(filename)
		if DirAccess.dir_exists_absolute(target):
			errors.append(tr("⚠ The StoryQuest folder %s already exists.") % target)
	return errors


func _on_create_storyquest(title: String, description: String, filename: String) -> void:
	assert(not validate_title(title).size())
	assert(not validate_filename(filename).size())

	var copier: Copier = Copier.new(filename, title, description)
	await copier.create_storyquest()
	_close_dialog()

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.select_file(copier.target_path)
