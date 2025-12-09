# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputHintManager
extends Resource

## Mapping from [class]InputHelper[/class] [code]DEVICE_X[/code] constants,
## such as [const InputHelper.DEVICE_STEAMDECK_CONTROLLER].
@export var device_map: Dictionary[String, JoypadButtonTextures]
