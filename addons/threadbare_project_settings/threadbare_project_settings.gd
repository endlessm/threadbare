# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name ThreadbareProjectSettings
extends EditorPlugin

const DEBUG_ASPECT_RATIO = "threadbare/debugging/debug_aspect_ratio"
const SKIP_SOKOBANS = "threadbare/debugging/skip_sokobans"

static var setttings_configuration = {
	DEBUG_ASPECT_RATIO:
	{
		value = false,
		type = TYPE_BOOL,
		hint_string = "Display a letterbox overlay in the game, to debug aspect ratio issues.",
	},
	SKIP_SOKOBANS:
	{
		value = false,
		type = TYPE_BOOL,
		hint_string = "Skip the sokobans from the core game loop, and complete the quest directly.",
	},
}


func _enter_tree() -> void:
	setup_threadbare_settings()


static func setup_threadbare_settings() -> void:
	for setting_name: String in setttings_configuration:
		var setting_config: Dictionary = setttings_configuration[setting_name]
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
		ProjectSettings.set_as_basic(setting_name, not setting_config.has("is_advanced"))
		ProjectSettings.set_as_internal(setting_name, setting_config.has("is_hidden"))
