# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Enums

enum LookAtSide {
	UNSPECIFIED = 0,
	LEFT = -1,
	RIGHT = 1,
}

## Collision layer names.
## [br][br]
## To access collision layers and masks by name rather than by number.
## Please keep this in sync with Project Settings layer_names/2d_physics/
enum CollisionLayers {
	PLAYERS = 1,
	NPCS = 2,
	PLAYER_DETECTORS = 3,
	SIGHT_OCCLUDERS = 4,
	WALLS = 5,
	INTERACTABLE = 6,
	PLAYERS_HITBOX = 7,
	ENEMIES_HITBOX = 8,
	PROJECTILES = 9,
	NON_WALKABLE_FLOOR = 10,
	HOOKABLE = 13,
}
