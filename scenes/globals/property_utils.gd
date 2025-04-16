# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PropertyUtils
extends Object


static func get_enum_hint_string(an_enum: Dictionary) -> String:
	var result := []
	for name: String in an_enum.keys():
		var readable_name: String = name.capitalize()
		result.append("%s:%d" % [readable_name, an_enum[name]])
	return ",".join(result)


static func enum_property(name: String, clazz: StringName, an_enum: Dictionary) -> Dictionary:
	return {
		"name": name,
		"type": TYPE_INT,
		"class_name": clazz,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": get_enum_hint_string(an_enum),
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_CLASS_IS_ENUM
	}


static func get_property_dict(obj: Object, property: String) -> Dictionary:
	for property_dict in obj.get_property_list():
		if property_dict["name"] == property:
			return property_dict

	return {}


static func expose_children_property(
	parent: Node2D, property: String, type: String = ""
) -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var children: Array = parent.find_children("*", type, false)
	for child: Node in children:
		var property_dict: Dictionary = get_property_dict(child, property)
		if not property_dict.is_empty():
			property_dict = property_dict.duplicate()
			property_dict["name"] = "%s__%s" % [child.name.to_snake_case(), property]
			properties.push_back(property_dict)

	return properties


static func _resolve_child_property(parent: Node, child_property_name: String) -> Dictionary:
	var parts: PackedStringArray = child_property_name.split("__", false)

	if parts.size() < 2:
		return {}

	var child_name: String = parts[0].to_pascal_case()
	var child_property: String = parts[1]

	var child: Node = parent.get_node_or_null(child_name)

	if not child:
		return {}

	return {"child": child, "property": child_property}


static func set_child_property(parent: Node, child_property_name: String, value: Variant) -> bool:
	var resolved_property: Dictionary = _resolve_child_property(parent, child_property_name)

	if resolved_property.is_empty():
		return false

	resolved_property["child"].set(resolved_property["property"], value)

	return true


static func get_child_property(parent: Node, child_property_name: String) -> Variant:
	var resolved_property: Dictionary = _resolve_child_property(parent, child_property_name)

	if resolved_property.is_empty():
		return null

	return resolved_property["child"].get(resolved_property["property"])
