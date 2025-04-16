# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Decoration
extends Node2D


func _set(property: StringName, value: Variant) -> bool:
	return PropertyUtils.set_child_property(self, property, value)


func _get(property: StringName) -> Variant:
	return PropertyUtils.get_child_property(self, property)


func _get_property_list() -> Array[Dictionary]:
	return PropertyUtils.expose_children_property(self, "texture", "Sprite2D")
