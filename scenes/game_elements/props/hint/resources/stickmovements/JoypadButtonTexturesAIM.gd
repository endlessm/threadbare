# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name JoypadButtonTexturesAim
extends Resource

# Exported textures for each aiming direction. Set these in the editor for each platform resource.
@export var aim_unpressed: Texture2D
@export var aim_up: Texture2D
@export var aim_down: Texture2D
@export var aim_left: Texture2D
@export var aim_right: Texture2D

# Add more aim actions here as your project requires.
func get_texture_for_action(action_name: String) -> Texture2D:
	# Match the action name and return the associated exported texture.
	match action_name:
		"aim_unpressed":
			return aim_unpressed
		"aim_up":
			return aim_up
		"aim_down":
			return aim_down
		"aim_left":
			return aim_left
		"aim_right":
			return aim_right
		_:
			return aim_unpressed
