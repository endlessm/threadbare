@tool
class_name ProjectSettingLabel
extends Label
## A label for displaying the value of a project setting.

const SETTING_PROPERTY = &"setting_name"
const DEFAULT_PROPERTY = &"default_value"

@export var setting_name: String = _get_initial_setting_name()
@export var default_value: String = _get_initial_default_value()


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var setting: String = _get_setting_recursive(setting_name, default_value)
	if setting.is_empty():
		return

	text = setting


func _property_can_revert(property: StringName) -> bool:
	return property in [SETTING_PROPERTY, DEFAULT_PROPERTY]


func _property_get_revert(property: StringName) -> Variant:
	match property:
		SETTING_PROPERTY:
			return _get_initial_setting_name()

		DEFAULT_PROPERTY:
			return _get_initial_default_value()

	return null


func _get_setting_recursive(
		setting: String,
		default: Variant = null
) -> String:
	var value: String = ProjectSettings.get_setting(setting, default)
	var next_value: String = ProjectSettings.get_setting(value, "")
	while not next_value.is_empty():
		value = next_value
		next_value = ProjectSettings.get_setting(next_value, "")

	return value


func _get_initial_setting_name() -> String:
	return ""


func _get_initial_default_value() -> String:
	return ""
