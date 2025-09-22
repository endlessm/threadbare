extends GitDescribeExtension

const APPEND_SETTING = "append_describe_to_project_name"
const PROJECT_NAME_SETTING = "application/config/name"

var cached_project_name: String
var nothing_to_undo: bool
var setting_enabled := false


func _init() -> void:
	ProjectSettings.settings_changed.connect(_on_settings_changed)
	PluginSettings.init_setting(APPEND_SETTING, false)


func _set_describe(describe: String) -> void:
	if not setting_enabled:
		return

	nothing_to_undo = describe.is_empty()
	if describe.is_empty():
		return

	cached_project_name = ProjectSettings.get_setting(PROJECT_NAME_SETTING)
	ProjectSettings.set_setting(
			PROJECT_NAME_SETTING,
			" ".join([cached_project_name, describe])
	)


func _erase_describe() -> void:
	if not setting_enabled:
		return

	if cached_project_name.is_empty():
		return

	if nothing_to_undo:
		return

	ProjectSettings.set_setting(PROJECT_NAME_SETTING, cached_project_name)
	cached_project_name = ""
	nothing_to_undo = true


func push_status() -> void:
	if (
			ProjectSettings.get_setting("use_custom_user_dir", false)
			and ProjectSettings.get_setting("custom_user_dir_name", "")
	):
		return

	push_warning(
			"Godot Git Describe: custom user dir not defined."
			 + " Changes to the describe string will change the user dir."
	)


func _on_settings_changed() -> void:
	var was_setting_enabled: bool = setting_enabled
	setting_enabled = PluginSettings.get_setting(APPEND_SETTING, false)
	if not setting_enabled:
		return

	if was_setting_enabled:
		return

	push_status()
