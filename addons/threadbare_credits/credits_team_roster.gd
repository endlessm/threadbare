# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CreditsTeamRoster
extends Resource
## Teams within a studio.
##
## This should typically be generated from a CSV file using the Threadbare
## Credits importer, but may be created by hand.

@export var teams: Array[CreditsTeam]
