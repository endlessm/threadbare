# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D

@export var character: CharacterBody2D


func _ready() -> void:
	if not character and owner is CharacterBody2D:
		character = owner


func _process(_delta: float) -> void:
	if not character:
		return
	if character.velocity.is_zero_approx():
		play(&"idle")
	else:
		if not is_zero_approx(character.velocity.x):
			flip_h = character.velocity.x < 0
		play(&"walk")
