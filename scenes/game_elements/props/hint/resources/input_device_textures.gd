# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name InputDeviceTextures
extends Resource

## Mapping from [class]InputHelper[/class] [code]DEVICE_X[/code] constants,
## such as [const InputHelper.DEVICE_STEAMDECK_CONTROLLER].
@export var joypads: Dictionary[String, JoypadTextures]

@export var keyboard: KeyboardMouseTextures
