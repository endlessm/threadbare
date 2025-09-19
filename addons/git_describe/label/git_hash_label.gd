@tool
@icon("icon.svg")
class_name GitHashLabel
extends ProjectSettingLabel
## A label that automatically displays the latest Git commit hash.


func _get_initial_setting_name() -> String:
	return "addons/git_describe/commit_hash"
