@tool
@icon("icon.svg")
class_name GitDescribeLabel
extends ProjectSettingLabel
## A label that automatically displays the Git describe string.


func _get_initial_setting_name() -> String:
	return "addons/git_describe/describe_setting_path"


func _get_initial_default_value() -> String:
	return "application/config/git_describe"
