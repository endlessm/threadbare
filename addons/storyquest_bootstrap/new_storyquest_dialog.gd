# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Window

signal create_storyquest(title: String, description: String, filename: String)
signal cancel

@export var storyquests_path: String
@export var validate_title: Callable
@export var validate_filename: Callable

var _title: String
var _description: String
var _filename: String
var _invalid_char_regex: RegEx

@onready var create_button: Button = %CreateButton
@onready var panel: Panel = %Panel
@onready var title_edit: LineEdit = %TitleEdit
@onready var folder_edit: LineEdit = %FolderEdit
@onready var full_path_label: Label = %FullPathLabel
@onready var errors_label: RichTextLabel = %ErrorsLabel
@onready var description_edit: TextEdit = %DescriptionEdit
@onready var progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = get_theme_color("dark_color_2", "Editor")
	panel.add_theme_stylebox_override("panel", style)
	title_edit.grab_focus()
	errors_label.add_theme_color_override(
		"default_color", get_theme_color("warning_color", "Editor")
	)

	_invalid_char_regex = RegEx.new()
	var error := _invalid_char_regex.compile("\\W+", true)
	assert(error == OK, error_string(error))


func _on_create_button_pressed() -> void:
	title_edit.editable = false
	description_edit.editable = false
	create_button.disabled = true
	progress_bar.visible = true
	progress_bar.indeterminate = true
	create_storyquest.emit(_title, _description, _filename)


func _on_close_requested() -> void:
	if not progress_bar.visible:
		cancel.emit()


func _make_filename(title: String) -> String:
	var snaked := title.to_snake_case()

	# Replace all runs of characters that are hard to type on US English
	# keyboards, and which are inconvenient or illegal in filenames (such as
	# leading dots, slashes, colons on Windows, etc.), with a single underscore.
	#
	# TODO: Replace e.g. ö with oe, ß with ss, ı with i, ñ with n, etc.
	# TODO: Transliterate non-Latin scripts
	var subbed := _invalid_char_regex.sub(snaked, "_", true)

	# Now remove leading or trailing underscores. This may mean the resulting
	# filename is empty.
	var stripped := subbed.lstrip("_").rstrip("_")

	# Limit the generated filename to a reasonable length.
	return stripped.left(folder_edit.max_length)


func _on_title_edit_text_changed(new_text: String) -> void:
	_title = new_text
	folder_edit.text = _make_filename(_title)
	_on_folder_edit_text_changed(folder_edit.text)


func _on_folder_edit_text_changed(new_text: String) -> void:
	_filename = new_text
	full_path_label.text = storyquests_path.path_join(_filename)
	_revalidate()


func _on_description_edit_text_changed() -> void:
	_description = description_edit.text


func _revalidate() -> void:
	var errors: PackedStringArray

	errors.append_array(validate_title.call(_title))

	var matches := _invalid_char_regex.search_all(_filename)
	if matches:
		for match: RegExMatch in matches:
			errors.append("⚠ ‘%s’ is not allowed in the folder name" % match.get_string(0))
	if _filename.to_lower() != _filename:
		errors.append("⚠ Folder name must be lower-case")
	if _title:
		errors.append_array(validate_filename.call(_filename))

	errors_label.text = "\n".join(errors)
	create_button.disabled = errors.size() > 0
