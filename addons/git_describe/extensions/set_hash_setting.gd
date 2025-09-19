extends GitDescribeExtension

const Utilities = preload("../utilities.gd")
const SETTING_NAME = "commit_hash"


func _set_describe(_describe: String) -> void:
	var results: Utilities.Results = Utilities.execute("git rev-parse HEAD")
	if results.exit_code != 0:
		return

	PluginSettings.set_setting(SETTING_NAME, results.output[0].strip_edges())


func _erase_describe() -> void:
	PluginSettings.set_setting(SETTING_NAME, null)
