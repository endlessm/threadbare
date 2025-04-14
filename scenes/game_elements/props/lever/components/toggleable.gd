# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Toggleable
extends Node2D


## Initialization of the toggleable. By default, it changes the toggled state.
## This method makes it so that when we run the game,
## the Toggleable MIGHT not be in the state that we see in the editor. For example:
##
## * We have an open door in the editor connected to a lever in OFF state.
## * In the editor, we see the door open (unless it and the lever are tools
## and all this code runs there too).
## * When we run the game, this method gets used and the door is closed by the lever.
##
## Subclasses can override for other behaviours.
func initialize_with_value(value: bool) -> void:
	set_toggled(value)


func set_toggled(_value: bool) -> void:
	# For subclasses to override (mandatory)
	assert(false, "Subclasses must override this method")
