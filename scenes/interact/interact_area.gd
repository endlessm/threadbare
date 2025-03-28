# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# SPDX-License-Identifier: MPL-2.0
class_name InteractArea
extends Area2D

signal interaction_started
signal interaction_ended

@export var action: String = "Talk"


func start_interaction() -> void:
	interaction_started.emit()


func end_interaction() -> void:
	interaction_ended.emit()
