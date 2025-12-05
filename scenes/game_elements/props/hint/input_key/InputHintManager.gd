# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHintManager
extends Resource

## Mapping from [class]InputHelper[/class] [code]DEVICE_X[/code] constants,
## such as [const InputHelper.DEVICE_STEAMDECK_CONTROLLER].
@export var device_map: Dictionary[String, JoypadButtonTextures]


## Get texture by device and action name
func get_texture_for(device: String, action_name: String) -> Texture2D:
	return device_map[device].get_texture_for_action(action_name)
