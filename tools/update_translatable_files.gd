# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name UpdateTranslatableFiles
extends EditorScript
## Maintains the list to files to translate from [const SOURCES]
##
## Because adding them one by one from the Project Settings Localization tab is tedious and
## prone to errors.
## [br][br]
## Edit [const SOURCES] then run this editor script. The list of translatable files will be
## updated.
## [br][br]
## If adding a directory path to [const SOURCES], this will search for .tscn files, .dialogue files,
## and .tres files that are [Quest] resources.
## [br][br]
## Adding a file path in [const SOURCES] adds the file directly. Use it for adding script files. In
## the future we could check for scripts that use [method Object.tr] in directory paths.
## [br][br]
## Use [const EXCLUDED] for files that match but shouldn't be listed.

## Folders to search or individual files to add.
const SOURCES: PackedStringArray = [
	"res://addons/storyquest_bootstrap",
	"res://addons/storyquest_bootstrap/plugin.gd",
	"res://scenes/dev",
	"res://scenes/game_elements",
	"res://scenes/game_elements/props/collectible_item/components/collectible_item.gd",
	"res://scenes/game_elements/props/powerup/components/powerup.gd",
	"res://scenes/game_logic",
	"res://scenes/game_logic/talk_behavior.gd",
	"res://scenes/globals/pause",
	"res://scenes/menus/debug",
	"res://scenes/menus/options",
	"res://scenes/menus/quest_separator",
	"res://scenes/menus/title/components/main_menu.tscn",
	"res://scenes/menus/title/components/main_menu.gd",
	"res://scenes/ui_elements/input_hints",
	"res://scenes/quests/template_quests/",
]

## Files found in [const SOURCES] but must not be listed.
const EXCLUDED: PackedStringArray = [
	# Strings in these lists are placeholders that are replaced at runtime:
	"res://scenes/menus/debug/debug_completed_quest_list.tscn",
	"res://scenes/menus/debug/debug_player_abilities_list.tscn",
	# Strings in the input HUD are the tab names, but the tabs are hidden. Alternatively we
	# could set these TabContainers to have auto_translate_mode disabled, but then each child node
	# would need to be changed from auto_translate_mode inherit to enabled:
	"res://scenes/ui_elements/input_hints/input_hud.tscn",
	# We are not translating the lore yet. Exclude lore elements inside game_elements:
	"res://scenes/game_elements/characters/npcs/elder/lore_quest_elder.tscn",
	"res://scenes/game_elements/characters/npcs/elder/components/lore_quest_starter.dialogue",
	"res://scenes/game_elements/props/eternal_loom/eternal_loom.tscn",
	"res://scenes/game_elements/props/eternal_loom/components/eternal_loom_interaction.dialogue",
]

## The Project Setting to update.
const POT_FILES_SETTING := "internationalization/locale/translations_pot_files"

## File extensions always considered as translatable.
const TRANSLATABLE_EXTENSIONS: PackedStringArray = ["tscn", "dialogue"]


func _run() -> void:
	var listed := PackedStringArray(
		ProjectSettings.get_setting(POT_FILES_SETTING, PackedStringArray())
	)

	var wanted := PackedStringArray()
	var is_wanted: Dictionary[String, bool] = {}
	for source: String in SOURCES:
		for path: String in _translatable_files(source):
			if is_wanted.has(path) or EXCLUDED.has(path):
				continue
			is_wanted[path] = true
			wanted.append(path)

	var added := PackedStringArray()
	for path: String in wanted:
		if not listed.has(path):
			added.append(path)

	var removed := PackedStringArray()
	for path: String in listed:
		if not is_wanted.has(path):
			removed.append(path)

	if added.is_empty() and removed.is_empty():
		print("The POT generation list already has the %d expected file(s)." % wanted.size())
		return

	ProjectSettings.set_setting(POT_FILES_SETTING, wanted)
	var error := ProjectSettings.save()
	if error != OK:
		push_error("Could not save the project settings: %s" % error_string(error))
		return

	print("The POT generation list now has %d file(s)." % wanted.size())
	for path: String in added:
		print("  + ", path)
	for path: String in removed:
		print("  - ", path)


## Returns the paths in [param source] that match for translation, sorted.
## A file is returned as-is, and folders are searched recursively.
func _translatable_files(source: String) -> PackedStringArray:
	if FileAccess.file_exists(source):
		return PackedStringArray([source])

	if not DirAccess.dir_exists_absolute(source):
		push_warning("%s is neither a file nor a folder, skipped." % source)
		return PackedStringArray()

	var files := PackedStringArray()
	var pending := PackedStringArray([source])

	while not pending.is_empty():
		var current := pending[-1]
		pending.remove_at(pending.size() - 1)

		for directory: String in DirAccess.get_directories_at(current):
			pending.append(current.path_join(directory))

		for file: String in DirAccess.get_files_at(current):
			var path := current.path_join(file)
			var extension := path.get_extension().to_lower()
			if extension in TRANSLATABLE_EXTENSIONS:
				files.append(path)
			elif extension == "tres" and _is_quest(path):
				files.append(path)

	files.sort()
	return files


## Returns whether [param path] is a [Quest] resource.
static func _is_quest(path: String) -> bool:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) is Quest
