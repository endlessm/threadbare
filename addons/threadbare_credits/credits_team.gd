# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CreditsTeam
extends Resource

@export var name: String = ""

## Optional logo for the team.
@export var logo: Texture2D

## Supports [RichTextLabel] BBCode markup. May be empty if the team needs no
## description.
@export_multiline var description: String = ""

@export var members: Array[Dictionary]
