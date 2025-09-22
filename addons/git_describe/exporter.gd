extends EditorExportPlugin

signal export_began
signal export_ended


func _get_name() -> String:
	return "godot_git_describe_exporter"


func _export_begin(
		_features: PackedStringArray,
		_is_debug: bool,
		_path: String,
		_flags: int
) -> void:
	export_began.emit()


func _export_end() -> void:
	export_ended.emit()
