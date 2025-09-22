extends GitDescribeExtension

const SETTING_NAME = "describe_setting_path"
const SETTING_DEFAULT_VALUE = "application/config/git_describe"


func _init() -> void:
	PluginSettings.init_setting(SETTING_NAME, SETTING_DEFAULT_VALUE)


func _set_describe(describe: String) -> void:
	set_describe_setting(describe)


func _erase_describe() -> void:
	set_describe_setting(null)


func set_describe_setting(value: Variant) -> void:
	var describe_setting: String = PluginSettings.get_setting(
			SETTING_NAME,
			SETTING_DEFAULT_VALUE
	)
	ProjectSettings.set_setting(describe_setting, value)
	ProjectSettings.save()
