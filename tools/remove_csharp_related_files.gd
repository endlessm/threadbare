# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorScript
## Removes the C# scripts, and the scenes and resources that use them
##
## Threadbare is written in GDScript only, so the C# variants that some addons
## ship are never loaded, and are unneeded weight. Run this in the editor after
## updating an addon, since the update brings them back. The report goes to the
## Output panel.
## [br][br]
## A scene or resource that uses a removed file is removed too, and so is anything
## that uses that scene, until nothing more is affected. Otherwise it would be
## left pointing at a file that is gone.

const Util = preload("./util.gd")

## Where to look for files. Everything under it is checked.
const ROOT_FOLDER := "res://"

const CSHARP_EXTENSION := "cs"

## Extensions of the files whose references to other files are followed.
const RESOURCE_EXTENSIONS: PackedStringArray = ["tscn", "tres"]


func _run() -> void:
	var files := Util.all_files(ROOT_FOLDER)

	var to_remove: Dictionary[String, bool] = {}
	for path: String in files:
		if path.get_extension() == CSHARP_EXTENSION:
			to_remove[path] = true

	var references: Dictionary[String, PackedStringArray] = {}
	for path: String in files:
		if path.get_extension() in RESOURCE_EXTENSIONS:
			references[path] = _external_references(path)

	# Each pass may mark for removal a scene that other scenes use, so this
	# repeats until a pass adds nothing.
	var grew := true
	while grew:
		grew = false
		var gone := _identifiers_of(to_remove.keys())
		for path: String in references:
			if to_remove.has(path):
				continue
			for referenced: String in references[path]:
				if gone.has(referenced):
					to_remove[path] = true
					grew = true
					break

	var removed: Array[String] = []
	var paths: Array = to_remove.keys()
	paths.sort()
	for path: String in paths:
		for target: String in [path, path + ".uid"]:
			if not FileAccess.file_exists(target):
				continue
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
			if error == OK:
				removed.append(target)
			else:
				push_error("Could not remove %s: %s" % [target, error_string(error)])

	var csharp := paths.filter(
		func(path: String) -> bool: return path.get_extension() == CSHARP_EXTENSION
	)
	print(
		(
			"Removed %d C# script(s) and %d scene(s) or resource(s) using them, %d file(s) in total:"
			% [csharp.size(), paths.size() - csharp.size(), removed.size()]
		)
	)
	for path: String in removed:
		print("  ", path)

	if not removed.is_empty():
		# The files changed behind the editor's back, so let it notice.
		EditorInterface.get_resource_filesystem().scan()


## Returns the path and UID of every [code]ext_resource[/code] in [param path].
func _external_references(path: String) -> PackedStringArray:
	var found_references := PackedStringArray()
	var content := FileAccess.get_file_as_string(path)

	var ext_resource := RegEx.create_from_string("(?m)^\\[ext_resource ([^\\]]*)\\]")
	# The boundary keeps the id attribute from being read as part of uid.
	var attribute := RegEx.create_from_string('\\b(path|uid)="([^"]+)"')

	for line: RegExMatch in ext_resource.search_all(content):
		for value: RegExMatch in attribute.search_all(line.get_string(1)):
			found_references.append(value.get_string(2))

	return found_references


## Returns the set of ways [param paths] can be referred to, which is their paths
## and their UIDs.
func _identifiers_of(paths: Array) -> Dictionary[String, bool]:
	var identifiers: Dictionary[String, bool] = {}

	for path: String in paths:
		identifiers[path] = true

		# A script keeps its UID next to it, in a .uid file.
		var sidecar := path + ".uid"
		if FileAccess.file_exists(sidecar):
			identifiers[FileAccess.get_file_as_string(sidecar).strip_edges()] = true

		var uid := ResourceUID.path_to_uid(path)
		if uid != path:
			identifiers[uid] = true

	return identifiers
