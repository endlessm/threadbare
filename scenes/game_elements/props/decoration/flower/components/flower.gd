# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Decoration
## Chooses a texture from a list, semi-randomly but deterministically
##
## The texture is chosen from [member textures] based on this node's path in the
## scene. This is useful for a flowerbed where each flower should be the same
## each time the game is run, unless the list of flower textures is changed.

## The textures to choose [member Decoration.texture] from.
@export var textures: Array[Texture2D]


func _ready() -> void:
	texture = textures[get_path().hash() % textures.size()]
