# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Toggleable
extends Node2D


## Initialization of the toggleable. By default, it changes the toggled state.
## Subclasses can override for other behaviours.
func initialize_with_value(value: bool) -> void:
	set_toggled(value)


func set_toggled(_value: bool) -> void:
	# For subclasses to override (mandatory)
	assert(false, "Subclasses must override this method")
