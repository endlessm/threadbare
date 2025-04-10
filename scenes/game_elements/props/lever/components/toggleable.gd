# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name Toggleable
extends Node2D


func initialize_with_value(_value: bool) -> void:
	# For subclasses to override (optional)
	pass


func change_value(_value: bool) -> void:
	# For subclasses to override (mandatory)
	assert(false, "Subclasses must override this method")
