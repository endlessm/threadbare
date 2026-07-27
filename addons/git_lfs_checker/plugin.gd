# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

const LFS_HEADER: String = "version https://git-lfs.github.com/spec/v1"
const LFS_DOCUMENTATION_URL: String = "https://github.com/endlessm/threadbare/discussions/772"

const WARNING_TITLE: String = "Git LFS not configured"
const WARNING_MESSAGE: String = """
This project uses Git Large File Storage for large files, such as art and music.

The project appears to have been cloned without Git LFS.

It will not work correctly until you set up Git LFS and re-clone the project.
"""
const OK_BUTTON_TEXT: String = "Learn More…"

var _dialog: AcceptDialog


func _enter_tree() -> void:
	if _lfs_missing():
		_show_lfs_warning()


## Returns true if the repo was cloned without Git LFS. Returns false in other
## cases, including if we're not sure.
func _lfs_missing() -> bool:
	var icon := ProjectSettings.get_setting("application/config/icon")
	var file := FileAccess.open(icon, FileAccess.READ)
	if not file:
		var error := FileAccess.get_open_error()
		push_warning("Failed to open ", icon, " to check for Git LFS: ", error_string(error))
		return false

	var lfs_header := LFS_HEADER.to_ascii_buffer()
	var header := file.get_buffer(lfs_header.size())
	return header == lfs_header


func _show_lfs_warning() -> void:
	_dialog = AcceptDialog.new()
	_dialog.title = WARNING_TITLE
	_dialog.dialog_autowrap = true
	_dialog.dialog_text = WARNING_MESSAGE.dedent().strip_edges()
	_dialog.ok_button_text = OK_BUTTON_TEXT
	EditorInterface.get_editor_main_screen().add_child(_dialog)
	_dialog.confirmed.connect(_show_lfs_documentation)
	_dialog.popup_centered()


func _show_lfs_documentation() -> void:
	OS.shell_open(LFS_DOCUMENTATION_URL)


func _exit_tree() -> void:
	if _dialog:
		_dialog.queue_free()
		_dialog = null
