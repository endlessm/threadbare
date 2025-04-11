# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PieceGroups
extends Resource
## A simple wrapper for a list of string identifiers for pieces.
##
## PieceGroups is used to identify pieces and is used in filters for Board2D,
## and in SokobanRules

@export var groups: Array[StringName]


static func is_valid(target_groups: PieceGroups) -> bool:
	return target_groups and not target_groups.is_empty()


static func from_group(target_group: StringName) -> PieceGroups:
	return PieceGroups.new([target_group])


func _init(i_groups: Array[StringName] = []) -> void:
	groups = i_groups


func get_size() -> int:
	return groups.size()


func is_empty() -> bool:
	return groups.size() == 0


func has_group(target_group: StringName) -> bool:
	return groups.has(target_group)


func has_groups(target_groups: PieceGroups) -> bool:
	if not target_groups:
		return false

	var result := true
	for target_group in target_groups.groups:
		if target_group not in groups:
			result = false
			break

	return result


func append(group: StringName) -> void:
	groups.append(group)


func remove(group: StringName) -> void:
	groups.erase(group)


func clear() -> void:
	groups.clear()
