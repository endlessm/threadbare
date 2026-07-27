# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name JoypadTextures
extends Resource

## Digital buttons which can be either pressed or unpressed: face, shoulders,
## and theoretically paddles.
@export var buttons: Dictionary[JoyButton, Texture2D]

@export var dpad: DirectionalInputTextures
@export var left_stick: DirectionalInputTextures
@export var right_stick: DirectionalInputTextures

## L2/R2 (aka LT/RT or ZL/ZR) are technically axes, but we treat them as buttons.
@export var triggers: Dictionary[JoyAxis, Texture2D]
