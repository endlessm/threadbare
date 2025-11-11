# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name JoypadButtonTextures
extends Resource

# Exported textures for each action. Set these in the editor for each platform resource.
@export var move_unpressed: Texture2D
@export var move_up: Texture2D
@export var move_down: Texture2D
@export var move_left: Texture2D
@export var move_right: Texture2D

# Add more actions here as your project requires.
func get_texture_for_action(action_name: String) -> Texture2D:
	# Match the action name and return the associated exported texture.
	match action_name:
		"move_unpressed":
			return move_unpressed
		"move_up":
			return move_up
		"move_down":
			return move_down
		"move_left":
			return move_left
		"move_right":
			return move_right
		_:
			return move_unpressed
