# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Trinket
extends Resource

@export var id: StringName
@export var name: String
@export var description: String
@export var icon: Texture2D
@export_multiline var full_text: String


func is_readable() -> bool:
	return not full_text.is_empty()
