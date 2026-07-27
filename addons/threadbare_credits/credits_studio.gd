# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CreditsStudio
extends Resource
## Describes a studio for the purposes of the credits page
##
## A studio has a name, optional logo, optional description, and a roster of
## team members.
##
## We stretch the definition of a studio slightly: the community is a studio,
## with mentors being a team within that studio; and third-party components are
## a studio, with teams including the Godot Engine project, Nathan Hoad, and
## "Creative Commons Assets".

## Name of the studio. Should not be blank.
@export var name: String = ""

## Optional logo for the studio.
@export var logo: Texture2D

## Supports [RichTextLabel] BBCode markup. May be empty if the studio needs no
## description.
@export_multiline var description: String = ""

## Studio staff, grouped by team. May be empty if [member description] suffices.
## [br][br]
## This is a separate resource rather than embedded in this one because
## [CreditsTeamRoster] can be imported from CSV files, which cannot easily refer
## to the logo texture etc.
@export var roster: CreditsTeamRoster
