# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Window

signal create_storyquest(title: String, description: String, filename: String)

@export var storyquests_path: String
@export var validate_title: Callable
@export var validate_filename: Callable

var _title: String
var _description: String
var _filename: String

@onready var create_button: Button = %CreateButton
@onready var panel: Panel = %Panel
@onready var title_edit: LineEdit = %TitleEdit
@onready var errors_label: RichTextLabel = %ErrorsLabel
@onready var folder_res_label: Label = %FolderResLabel
@onready var description_edit: TextEdit = %DescriptionEdit


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = get_theme_color("dark_color_2", "Editor")
	panel.add_theme_stylebox_override("panel", style)
	title_edit.grab_focus()
	errors_label.add_theme_color_override(
		"default_color", get_theme_color("warning_color", "Editor")
	)


func _on_create_button_pressed() -> void:
	create_storyquest.emit(_title, _description, _filename)


func _make_filename(title: String) -> String:
	var snaked := title.to_snake_case()

	# Replace all runs of characters that are hard to type on US English
	# keyboards, and which are inconvenient or illegal in filenames (such as
	# leading dots, slashes, colons on Windows, etc.), with a single underscore.
	#
	# TODO: Replace e.g. ö with oe, ß with ss, ı with i, ñ with n, etc.
	# TODO: Transliterate non-Latin scripts
	var regex := RegEx.new()
	var error := regex.compile("\\W+", true)
	assert(error == OK, error_string(error))
	var subbed := regex.sub(snaked, "_", true)

	# Now remove leading or trailing underscores. This may
	var stripped := subbed.lstrip("_").rstrip("_")

	return stripped


func _on_title_edit_text_changed(new_text: String) -> void:
	_title = new_text
	_filename = _make_filename(_title)

	var errors: PackedStringArray
	errors.append_array(validate_title.call(_title))
	if _title:
		errors.append_array(validate_filename.call(_filename))

	create_button.disabled = errors.size()
	folder_res_label.text = storyquests_path.path_join(_filename)
	errors_label.text = "\n".join(errors)


func _on_description_edit_text_changed() -> void:
	_description = description_edit.text
