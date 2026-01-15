# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends EditorImportPlugin


func _get_importer_name() -> String:
	return "game.threadbare.credits"


func _get_visible_name() -> String:
	return "Threadbare Credits"


func _get_recognized_extensions() -> PackedStringArray:
	return ["csv"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_count() -> int:
	return 1


func _get_preset_name(_preset_index: int) -> String:
	return "Default"


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []


func zip(keys: PackedStringArray, values: PackedStringArray) -> Dictionary[String, String]:
	var result: Dictionary[String, String]
	for i: int in range(keys.size()):
		result[keys[i]] = values[i] if i < values.size() else ""
	return result


func _import(
	source_file: String,
	save_path: String,
	_options: Dictionary,
	_platform_variants: Array[String],
	_gen_files: Array[String]
) -> Error:
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED

	var header_line := file.get_csv_line()
	if header_line.size() == 1 and header_line[0] == "":
		push_error(source_file, "is empty")
		return FAILED

	var roster := CreditsTeamRoster.new()
	var team: CreditsTeam

	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 1 and line[0] == "":
			break
		var record := zip(header_line, line)
		record.make_read_only()
		var team_name := record.get("Team", "")
		if not team or team_name != team.name:
			team = CreditsTeam.new()
			team.name = team_name
			roster.teams.append(team)
		team.members.append(record)
	team.members.make_read_only()

	var filename := save_path + "." + _get_save_extension()
	return ResourceSaver.save(roster, filename)
