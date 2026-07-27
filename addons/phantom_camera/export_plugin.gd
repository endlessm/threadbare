extends EditorExportPlugin
## Excludes Phantom Camera files that are not needed in exported game
##
## Annoyingly EditorExportPlugin._export_file() is not called for .gd files, so
## (for example) example scripts are included in the export.

const IGNORED_PATHS := [
	"/assets",
	"/examples",
	"/fonts",
	"/inspector",
	"/panel",
	"/scripts/panel",
	"/themes",
]


func _get_name() -> String:
	return "Phantom Camera Export Plugin"


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	var plugin_path: String = self.get_script().resource_path.get_base_dir()
	for ignored_path: String in IGNORED_PATHS:
		if path.begins_with(plugin_path + ignored_path):
			skip()
