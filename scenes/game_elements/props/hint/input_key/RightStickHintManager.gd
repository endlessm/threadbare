# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name RightStickHintController
extends Node

# Device keyword → resource path
const DEVICE_MAP := {
	"keyboard": "res://scenes/game_elements/props/hint/resources/stickmovements/Aim_keyboard.tres",
	"xbox": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_xbox.tres",
	"playstation":
	"res://scenes/game_elements/props/hint/resources/stickmovements/stick_playstation.tres",
	"ps": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_playstation.tres",
	"play": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_playstation.tres",
	"switch": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_switch.tres",
	"nintendo": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_switch.tres",
	"steam": "res://scenes/game_elements/props/hint/resources/stickmovements/stick_steamdeck.tres",
	"steamdeck":
	"res://scenes/game_elements/props/hint/resources/stickmovements/stick_steamdeck.tres"
}

# Fallback genérico
const GENERIC_RESOURCE := (
	"res://scenes/game_elements/props/hint/resources/" + "stickmovements/stick_xbox.tres"
)


# Determine which JoypadButtonTextures resource to use for a given device string.
func _resource_for_device(device: String) -> JoypadButtonTexturesAim:
	if device == null or device.is_empty():
		return ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTexturesAim

	var d := device.to_lower()
	for key: String in DEVICE_MAP.keys():
		if key in d:
			return ResourceLoader.load(DEVICE_MAP[key]) as JoypadButtonTexturesAim

	return ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTexturesAim


## Get texture by device and action name, with fallback to generic (xbox).
func get_texture_for(device: String, action_name: String) -> Texture2D:
	var res := _resource_for_device(device)
	if res:
		var tex := res.get_texture_for_action(action_name)
		if tex:
			return tex

	var generic_res := ResourceLoader.load(GENERIC_RESOURCE) as JoypadButtonTexturesAim

	if generic_res:
		return generic_res.get_texture_for_action(action_name)

	return null
