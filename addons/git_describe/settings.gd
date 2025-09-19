@tool
extends RefCounted

const SETTINGS_BASE_PATH = "addons/git_describe"


static func init_setting(
		partial_name: String,
		initial_value: Variant,
		basic := true,
		restart_if_changed := false,
		property_info := {}
) -> void:
	var setting_name: String = SETTINGS_BASE_PATH.path_join(partial_name)
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, initial_value)

	if property_info.has("type"):
		property_info["name"] = setting_name
		ProjectSettings.add_property_info(property_info)

	ProjectSettings.set_as_basic(setting_name, basic)
	ProjectSettings.set_initial_value(setting_name, initial_value)
	ProjectSettings.set_restart_if_changed(setting_name, restart_if_changed)


static func get_setting(
		partial_name: String,
		default_value: Variant = null
) -> Variant:
	return ProjectSettings.get_setting(
			SETTINGS_BASE_PATH.path_join(partial_name),
			default_value
	)


static func set_setting(partial_name: String, value: Variant) -> void:
	ProjectSettings.set_setting(
			SETTINGS_BASE_PATH.path_join(partial_name),
			value
	)
	ProjectSettings.save()


static func sort_settings() -> void:
	var property_list: Array[Dictionary] = ProjectSettings.get_property_list()
	var properties_to_sort: Array[Dictionary] = []
	var order_start: int = property_list.size()
	for property in property_list:
		var property_name: String = property.name
		if not property_name.begins_with(SETTINGS_BASE_PATH):
			continue

		var order: int = ProjectSettings.get_order(property_name)
		if order < order_start:
			order_start = order

		properties_to_sort.append(property)

	properties_to_sort.sort_custom(_setting_sort)
	for i in range(properties_to_sort.size()):
		ProjectSettings.set_order(
				properties_to_sort[i].name as String,
				order_start + i
		)


static func _setting_sort(a: Dictionary, b: Dictionary) -> bool:
	var a_is_basic: bool = a.usage & PROPERTY_USAGE_EDITOR_BASIC_SETTING
	var b_is_basic: bool = b.usage & PROPERTY_USAGE_EDITOR_BASIC_SETTING
	if a_is_basic != b_is_basic:
		return a_is_basic

	return a.name < b.name
