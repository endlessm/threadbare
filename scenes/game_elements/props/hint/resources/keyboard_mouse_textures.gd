# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name KeyboardMouseTextures
extends Resource

## Mapping from logical keycode to texture to show for that logical key.
## [const Key.KEY_UP], [const Key.KEY_DOWN], [const Key.KEY_LEFT], and [const
## Key.KEY_RIGHT] are handled specially in [member arrow_keys].
@export var keys: Dictionary[Key, Texture2D]

## The four arrow keys treated as a single glyph, with different textures
## depending on which key (if any) is pressed.
@export var arrow_keys: DirectionalInputTextures

@export var mouse_buttons: Dictionary[MouseButton, Texture2D]
