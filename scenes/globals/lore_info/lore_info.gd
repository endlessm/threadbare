# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name LoreInfo

## The abilities names or verbs as they appear in game labels. For example: "You got a new
## ability! Repel".
const ABILITIES_NAMES: Dictionary[Enums.PlayerAbilities, String] = {
	Enums.PlayerAbilities.ABILITY_A: "Repel",
	Enums.PlayerAbilities.ABILITY_B: "Grapple",
	Enums.PlayerAbilities.ABILITY_B_MODIFIER_1: "Longer Thread",
	# TODO: This should be moved to ABILITY_A_MODIFIER_1
	Enums.PlayerAbilities.ABILITY_C: "Hum",
}
