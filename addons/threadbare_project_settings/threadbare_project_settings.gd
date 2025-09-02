# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorPlugin

## Debug aspect ratio while playing the game.
const DEBUG_ASPECT_RATIO = "debugging/debug_aspect_ratio"

static var setttings_configuration = {
	DEBUG_ASPECT_RATIO:
	{
		value = false,
		type = TYPE_BOOL,
	},
}


func _enter_tree() -> void:
	setup_threadbare_settings()


static func setup_threadbare_settings() -> void:
	for key: String in setttings_configuration:
		var setting_config: Dictionary = setttings_configuration[key]
		var setting_name: String = "threadbare/%s" % key

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
