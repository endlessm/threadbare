# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHintManager
extends Node

# generic fallback
const GENERIC_RESOURCE := "res://scenes/game_elements/props/hint/resources/input_tres/xbox.tres"

# MULTI-FILE DEVICE MAP
# Each device maps to an Array of .tres files
var device_map := {
	"xbox":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/xbox.tres",
	],
	"play":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/playstation.tres",
	],
	"ps":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/playstation.tres",
	],
	"playstation":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/playstation.tres",
	],
	"switch":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/switch.tres",
	],
	"nintendo":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/switch.tres",
	],
	"steam":
	[
		"res://scenes/game_elements/props/hint/resources/input_tres/steamdeck.tres",
	],
	"steamdeck":
	[
		"res://scenes/game_elements/props/hint/resources/input.tres/steamdeck.tres",
	],
	"keyboard": ["res://scenes/game_elements/props/hint/resources/input_tres/keyboard.tres"],
}

# loaded resource cache
var resource_cache: Dictionary = {}


# Load a resource with caching
func _load_resource(path: String) -> Resource:
	if resource_cache.has(path):
		return resource_cache[path]

	var r := ResourceLoader.load(path)
	if r != null:
		resource_cache[path] = r
	return r


# Get the appropriate JoypadButtonTextures resource
# for the given detected device
func _resource_for_device(device: String) -> JoypadButtonTextures:
	if device == null or device.is_empty():
		return _load_resource(GENERIC_RESOURCE) as JoypadButtonTextures

	var d := device.to_lower()

	for key: String in device_map.keys():
		if key in d:
			var paths := device_map[key] as Array  # <- SAFE
			for p: String in paths:
				var res := _load_resource(p)
				if res != null:
					return res as JoypadButtonTextures

	# final fallback
	return _load_resource(GENERIC_RESOURCE) as JoypadButtonTextures


# Public accessor — returns Texture2D for given action
func get_texture_for(device: String, action_name: String) -> Texture2D:
	var res := _resource_for_device(device)
	if res != null:
		var tex := res.get_texture_for_action(action_name)
		if tex != null:
			return tex

	# fallback to generic if not found
	var g := _load_resource(GENERIC_RESOURCE) as JoypadButtonTextures
	if g != null:
		return g.get_texture_for_action(action_name)

	return null
