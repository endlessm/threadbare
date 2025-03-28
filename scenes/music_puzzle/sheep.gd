# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
extends AnimatedSprite2D


func _ready() -> void:
	hide()


func _on_music_puzzle_solved() -> void:
	show()
	play()
