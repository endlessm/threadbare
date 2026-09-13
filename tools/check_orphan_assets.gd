# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CheckOrphanAssets
extends EditorScript
## Reports assets that nothing in the project references
##
## Edit [const ROOT_FOLDER] then run this in the editor. The report goes to the
## Output panel, split into assets that nothing references, and [code].import[/code]
## files whose source file is gone. Those are two different problems: the first
## is an asset to delete, the second is a leftover to delete along with whatever
## produced it.
## [br][br]
## References come from [method ResourceLoader.get_dependencies], so an asset
## that is only ever referenced by its UID still counts as used. Scripts are
## scanned as text instead, because [code]preload()[/code] and
## [code]load()[/code] calls are not recorded as dependencies. A path assembled
## at run time cannot be detected either way.

## Where to look for assets. Everything under it is checked.
const ROOT_FOLDER := "res://scenes/quests/story_quests/stella"

## Extensions considered assets, lowercase and without the dot.
const ASSET_EXTENSIONS: PackedStringArray = [
	"png", "jpg", "jpeg", "webp", "svg", "ogg", "wav", "mp3", "ttf", "otf", "ogv"
]

## Extensions of files whose dependencies the engine tracks.
const RESOURCE_EXTENSIONS: PackedStringArray = ["tscn", "tres"]

const IMPORT_SUFFIX := ".import"


func _run() -> void:
	var referenced := _collect_referenced()

	var orphans: Array[String] = []
	var stale: Array[String] = []
	for path: String in _all_files(ROOT_FOLDER):
		if path.ends_with(IMPORT_SUFFIX):
			# A .import without its source is a leftover, not an unused asset.
			if not FileAccess.file_exists(path.trim_suffix(IMPORT_SUFFIX)):
				stale.append(path)
		elif path.get_extension().to_lower() in ASSET_EXTENSIONS:
			if not referenced.has(path) and not referenced.has(ResourceUID.path_to_uid(path)):
				orphans.append(path)

	orphans.sort()
	stale.sort()

	print("Assets under %s that nothing references: %d" % [ROOT_FOLDER, orphans.size()])
	for path: String in orphans:
		# The UID is printed because scenes usually reference assets by UID, so
		# it is what you need to search for to double check a result.
		print("  %s  %s" % [path, ResourceUID.path_to_uid(path)])

	print("\nStale %s files, with no source file: %d" % [IMPORT_SUFFIX, stale.size()])
	for path: String in stale:
		print("  ", path)

	print("\nNote: assets loaded through a path built at run time cannot be detected.")


## Returns the set of every resource path and UID referenced from anywhere in the
## project, as a [Dictionary] used as a set.
func _collect_referenced() -> Dictionary[String, bool]:
	var referenced: Dictionary[String, bool] = {}

	var uid_or_path := RegEx.create_from_string("(?:uid|res)://[^\"')\\s]+")

	for path: String in _all_files("res://"):
		var extension := path.get_extension().to_lower()

		if extension in RESOURCE_EXTENSIONS:
			for dependency: String in ResourceLoader.get_dependencies(path):
				# Dependencies read "uid://a::Type::res://b", and either half is
				# enough to count as a reference, so keep both.
				for part: String in dependency.split("::"):
					if part.begins_with("uid://") or part.begins_with("res://"):
						referenced[part] = true

		elif extension == "gd":
			var source := FileAccess.get_file_as_string(path)
			for found: RegExMatch in uid_or_path.search_all(source):
				referenced[found.get_string()] = true

	return referenced


## Returns every file under [param folder], recursively.
func _all_files(folder: String) -> PackedStringArray:
	var files := PackedStringArray()
	var pending := PackedStringArray([folder])

	while not pending.is_empty():
		var current := pending[-1]
		pending.remove_at(pending.size() - 1)

		for directory: String in DirAccess.get_directories_at(current):
			# Godot's own cache holds copies of everything and would count as
			# references to assets that are otherwise unused.
			if directory != ".godot":
				pending.append(current.path_join(directory))

		for file: String in DirAccess.get_files_at(current):
			files.append(current.path_join(file))

	return files
