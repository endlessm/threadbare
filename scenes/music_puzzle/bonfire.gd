# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
class_name Bonfire
extends StaticBody2D

@onready var fire: AnimatedSprite2D = %Fire


func ignite() -> void:
	fire.play(&"burning")
