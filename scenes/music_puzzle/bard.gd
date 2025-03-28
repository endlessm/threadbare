# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
## A talker who can also play a musical instrument
@tool
class_name Bard
extends Talker

@export var puzzle: MusicPuzzle

var first_conversation: bool = true


func play(note: String) -> void:
	await puzzle.xylophone.play_note(note)
