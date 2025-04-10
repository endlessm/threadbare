# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name PropertyUtils
extends Object


static func get_enum_hint_string(an_enum: Dictionary) -> String:
	var result := []
	for name in an_enum.keys():
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
