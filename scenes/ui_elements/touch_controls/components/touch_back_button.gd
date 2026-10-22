# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Control
## A button to go back, shown only while using the touch controls. See
## [member Settings.touch_controls].
##
## Add it to scenes that show an input hint to go back, like the credits or the
## storybook. It's in the same place as the pause button of the touch controls,
## which are hidden while these scenes are shown.

## The input action that the button presses, which should be the action of the
## input hint to go back.
@export var action: StringName = &"ui_cancel"

@onready var back_button: TouchScreenButton = %BackButton


func _ready() -> void:
	back_button.action = action
	Settings.touch_controls_changed.connect(_update_visibility)
	_update_visibility()


func _update_visibility() -> void:
	visible = Settings.touch_controls
