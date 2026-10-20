# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CheckOrphanAssets
extends EditorScript
## Reports assets that nothing in the project references
##
## Edit [const ROOT_FOLDER] then run this in the editor. The report goes to the
## Output panel, split into folders that are made up entirely of unreferenced assets,
## unreferenced assets outside of those folders, and [code].import[/code] files whose
## source file is gone. The first two are assets to delete (grouped by folder when a
## whole one can go), the third is a leftover to delete along with whatever produced it.
## [br][br]
## References come from [method ResourceLoader.get_dependencies], so an asset
## that is only ever referenced by its UID still counts as used. Scripts are
## scanned as text instead, because [code]preload()[/code] and
## [code]load()[/code] calls are not recorded as dependencies. A path assembled
## at run time cannot be detected either way.

const Util = preload("./util.gd")

## Where to look for assets. Everything under it is checked.
const ROOT_FOLDER := "res://scenes/quests/story_quests/stella"

## Folders to skip when looking for references. This is useful when checking for assets that can be
## stripped from the StoryQuest kit.
const SKIP_FOLDERS: PackedStringArray = [
#"res://scenes/quests/story_quests"
]

## Extensions considered assets, lowercase and without the dot.
const ASSET_EXTENSIONS: PackedStringArray = [
	"png", "jpg", "jpeg", "webp", "svg", "ogg", "wav", "mp3", "ttf", "otf", "ogv"
]

## Extensions of files whose dependencies the engine tracks.
const RESOURCE_EXTENSIONS: PackedStringArray = ["tscn", "tres"]

const IMPORT_SUFFIX := ".import"


func _run() -> void:
	var referenced := _collect_referenced()

	var orphans: Dictionary[String, bool] = {}
	var stale: Array[String] = []
	for path: String in Util.all_files(ROOT_FOLDER, SKIP_FOLDERS):
		if path.ends_with(IMPORT_SUFFIX):
			# A .import without its source is a leftover, not an unused asset.
			if not FileAccess.file_exists(path.trim_suffix(IMPORT_SUFFIX)):
				stale.append(path)
		elif path.get_extension().to_lower() in ASSET_EXTENSIONS:
			if not referenced.has(path) and not referenced.has(ResourceUID.path_to_uid(path)):
				orphans[path] = true

	var fully_orphaned: Dictionary[String, bool] = {}
	_mark_fully_orphaned(ROOT_FOLDER, orphans, fully_orphaned)

	var orphan_folders: Array[String] = []
	var orphan_files: Array[String] = []
	_collect_orphans(ROOT_FOLDER, orphans, fully_orphaned, orphan_folders, orphan_files)

	orphan_folders.sort()
	orphan_files.sort()
	stale.sort()

	prints(
		"Folders under",
		ROOT_FOLDER,
		"made up entirely of unreferenced assets:",
		orphan_folders.size()
	)
	for folder: String in orphan_folders:
		print("  ", folder)

	print("\nOther assets that nothing references: %d" % orphan_files.size())
	for path: String in orphan_files:
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

	for path: String in Util.all_files("res://", SKIP_FOLDERS):
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


## Computes, for [param folder] and every folder recursively inside it, whether every
## asset file it (recursively) contains is in [param orphans], storing the result for
## each folder in [param fully_orphaned] as a set. A folder with no asset files anywhere
## inside it does not count, since there would be nothing to report.
## [br][br]
## Returns [code][has_asset, all_orphan][/code] for [param folder] itself, which is all
## the caller needs to fold [param folder] into its own parent's result.
func _mark_fully_orphaned(
	folder: String, orphans: Dictionary[String, bool], fully_orphaned: Dictionary[String, bool]
) -> Array[bool]:
	var has_asset := false
	var all_orphan := true

	for file: String in DirAccess.get_files_at(folder):
		var path := folder.path_join(file)
		if path.get_extension().to_lower() in ASSET_EXTENSIONS:
			has_asset = true
			if not orphans.has(path):
				all_orphan = false

	for directory: String in DirAccess.get_directories_at(folder):
		if directory != ".godot":
			var result := _mark_fully_orphaned(folder.path_join(directory), orphans, fully_orphaned)
			if result[0]:
				has_asset = true
				if not result[1]:
					all_orphan = false

	fully_orphaned[folder] = has_asset and all_orphan
	return [has_asset, all_orphan]


## Walks [param folder], recursively, using [param fully_orphaned] (as computed by
## [method _mark_fully_orphaned]) to split [param orphans] in two: the topmost folders
## that are made up entirely of unreferenced assets go into [param orphan_folders], and
## whatever is left - unreferenced assets that share a folder with a referenced one - goes
## into [param orphan_files].
func _collect_orphans(
	folder: String,
	orphans: Dictionary[String, bool],
	fully_orphaned: Dictionary[String, bool],
	orphan_folders: Array[String],
	orphan_files: Array[String]
) -> void:
	if fully_orphaned.get(folder, false):
		orphan_folders.append(folder)
		return

	for file: String in DirAccess.get_files_at(folder):
		var path := folder.path_join(file)
		if orphans.has(path):
			orphan_files.append(path)

	for directory: String in DirAccess.get_directories_at(folder):
		if directory != ".godot":
			_collect_orphans(
				folder.path_join(directory), orphans, fully_orphaned, orphan_folders, orphan_files
			)
