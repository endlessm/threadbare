# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D

@onready var buttons: Node2D = %Buttons


func all_buttons_collected() -> bool:
	return buttons.get_child_count() == 0
