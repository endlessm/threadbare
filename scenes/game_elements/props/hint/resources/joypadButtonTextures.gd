# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name JoypadButtonTextures
extends Resource
## Holds the textures for different actions on a particular type of joypad (or keyboard).

## Textures for the [code]move_*[/code] actions
@export var move: DirectionalInputTextures

## Textures for the [code]aim_*[/code] actions
@export var aim: DirectionalInputTextures

## Texture for the [code]running[/code] action
@export var running: Texture2D

## Texture for the [code]interact[/code] action
@export var interact: Texture2D

## Texture for the [code]repel[/code] action
@export var repel: Texture2D

## Alternative texture for the [code]repel[/code] action (i.e. the keyboard key
## as opposed to mouse button)
@export var repel_alt: Texture2D

## Texture for the [code]throw[/code] action
@export var throw: Texture2D

## Alternative texture for the [code]throw[/code] action (i.e. the keyboard key
## as opposed to mouse button)
@export var throw_alt: Texture2D

## Texture for the [code]sokoban_undo[/code] action
@export var sokoban_undo: Texture2D

## Texture for the [code]sokoban_reset[/code] action
@export var sokoban_reset: Texture2D

## Texture for the [code]sokoban_skip[/code] action
@export var sokoban_skip: Texture2D


## Returns the texture for a directional action. For instance, to get the
## correct texture for the [code]aim_left[/code] action, use:
## [codeblock]get_direction(&"aim", &"left")[/codeblock]
## For the texture when no direction is pressed for that action, pass
## [code]&"unpressed"[/code] for [param direction].
func get_direction(prefix: StringName, direction: StringName) -> Texture2D:
	var textures: DirectionalInputTextures = get(prefix)
	var texture: Texture2D
	if textures:
		texture = textures.get(direction)
	return texture
