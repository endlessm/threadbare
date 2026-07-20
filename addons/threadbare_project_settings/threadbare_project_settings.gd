# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThreadbareProjectSettings
extends Node

## The scene to return to when a quest is completed, skipped, or abandoned.
## (This is Fray's End in normal builds of Threadbare.)
const HOME_SCENE = "threadbare/general/home_scene"

## The [Quest] to start from the “New Game” title screen item. (This is the
## tutorial in normal builds of Threadbare.)
const OPENING_QUEST = "threadbare/general/opening_quest"

## Display a letterbox overlay in the game, to debug aspect ratio
const DEBUG_ASPECT_RATIO = "threadbare/debugging/debug_aspect_ratio"

## Skip the splash screen and title menu, and resume the game state. Like when clicking Continue.
const SKIP_SPLASH = "threadbare/debugging/skip_splash"

static var settings_configuration = {
	HOME_SCENE:
	{
		value = "uid://cufkthb25mpxy",
		type = TYPE_STRING,
		hint = PROPERTY_HINT_FILE,
		hint_string = "*.tscn",
	},
	OPENING_QUEST:
	{
		value = "uid://0dcffjdxn6g2",
		type = TYPE_STRING,
		hint = PROPERTY_HINT_FILE,
		hint_string = "*.tres,*.res",
	},
	DEBUG_ASPECT_RATIO:
	{
		value = false,
		type = TYPE_BOOL,
	},
	SKIP_SPLASH:
	{
		value = false,
		type = TYPE_BOOL,
	},
}


static func setup_threadbare_settings() -> void:
	for setting_name: String in settings_configuration:
		var setting_config: Dictionary = settings_configuration[setting_name]
		assert(setting_name.begins_with("threadbare"))

		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, setting_config.value)
		ProjectSettings.set_initial_value(setting_name, setting_config.value)
		ProjectSettings.add_property_info(
			{
				"name": setting_name,
				"type": setting_config.type,
				"hint": setting_config.get("hint", PROPERTY_HINT_NONE),
				"hint_string": setting_config.get("hint_string", "")
			}
		)
		ProjectSettings.set_as_basic(setting_name, not setting_config.get("is_advanced", false))
		ProjectSettings.set_as_internal(setting_name, setting_config.get("is_hidden", false))


## Gets a Threadbare-specific setting, returning its default value if unset in
## the project settings. [param key] should be one of the constants defined in
## [ThreadbareProjectSettings].
static func get_setting(key: String) -> Variant:
	assert(key in settings_configuration)
	return ProjectSettings.get_setting(key, settings_configuration[key].value)
