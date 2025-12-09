# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name DirectionalInputTextures
extends Resource
## Textures to show for a 2-dimensional input, such as D-pad, joystick, or keyboard arrow keys.
##
## Currently only the four cardinal directions are supported: [member up],
## [member down], [member left], [member right]. [member unpressed] is the
## texture to show when no direction is pressed.

## Texture for when no direction is pressed
@export var unpressed: Texture2D
## Texture for when the up direction is pressed
@export var up: Texture2D
## Texture for when the down direction is pressed
@export var down: Texture2D
## Texture for when the left direction is pressed
@export var left: Texture2D
## Texture for when the right direction is pressed
@export var right: Texture2D
