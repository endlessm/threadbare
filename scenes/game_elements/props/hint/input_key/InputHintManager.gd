# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHintManager
extends Node

# This script manages loading and providing textures for input hints.
# It finds which controller (Xbox, PlayStation, etc.) is currently used
# and returns the proper texture for a given action.

## Mapping of controller keyword -> resource path
const DEVICE_MAP: Dictionary = {
	"xbox": "res://scenes/game_elements/props/hint/resources/xbox.tres",
	"play": "res://scenes/game_elements/props/hint/resources/playstation.tres",
	"ps": "res://scenes/game_elements/props/hint/resources/playstation.tres",
	"playstation": "res://scenes/game_elements/props/hint/resources/playstation.tres",
	"switch": "res://scenes/game_elements/props/hint/resources/switch.tres",
	"nintendo": "res://scenes/game_elements/props/hint/resources/switch.tres",
	"steam": "res://scenes/game_elements/props/hint/resources/steamdeck.tres",
	"steamdeck": "res://scenes/game_elements/props/hint/resources/steamdeck.tres",
	"keyboard": "res://scenes/game_elements/props/hint/resources/keyboard.tres"
}

# NOTE: Use xbox.tres as the "generic" fallback resource.
# This makes xbox icons the default when no specific match is found.
const GENERIC_RESOURCE: String = "res://scenes/game_elements/props/hint/resources/xbox.tres"


func _load_resource(path: String) -> Resource:
	   return ResourceLoader.load(path)

# Determine which JoypadButtonTextures resource to use for a given device string.
func _resource_for_device(device: String) -> JoypadButtonTextures:
	# If device is null or empty, return generic resource.
	if device == null or device.is_empty():
		return ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTextures

	var d: String = device.to_lower()
	for key: String in DEVICE_MAP.keys():
		if key in d:
			return ResourceLoader.load(DEVICE_MAP[key]) as JoypadButtonTextures
	return ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTextures


## Get texture by device and action name, with fallback to generic (xbox).
func get_texture_for(device: String, action_name: String) -> Texture2D:
	var res: JoypadButtonTextures = _resource_for_device(device)
	if res:
		var tex: Texture2D = res.get_texture_for_action(action_name)
		if tex:
			return tex
	# Fallback to generic resource's action texture if not found in specific resource.
	var generic_res: JoypadButtonTextures = ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTextures
	if generic_res:
		return generic_res.get_texture_for_action(action_name)
	return null
