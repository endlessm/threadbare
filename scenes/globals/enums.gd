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

## Flags for player abilities
## [br][br]
## These are generic flags that can be treated differently
## in the lore game and in StoryQuests.
enum PlayerAbilities {
	ABILITY_A = 1 << 0,
	ABILITY_A_MODIFIER_1 = 1 << 1,
	ABILITY_A_MODIFIER_2 = 1 << 2,
	ABILITY_A_MODIFIER_3 = 1 << 3,
	ABILITY_B = 1 << 4,
	ABILITY_B_MODIFIER_1 = 1 << 5,
	ABILITY_B_MODIFIER_2 = 1 << 6,
	ABILITY_B_MODIFIER_3 = 1 << 7,
	ABILITY_C = 1 << 8,
	ABILITY_C_MODIFIER_1 = 1 << 9,
	ABILITY_C_MODIFIER_2 = 1 << 10,
	ABILITY_C_MODIFIER_3 = 1 << 11,
}
