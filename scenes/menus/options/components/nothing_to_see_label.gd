# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Label
## A label for a settings page whose settings can all be hidden.
##
## Shows itself only when every control in [member settings] is hidden, so the
## page doesn't look broken. For example, on a phone without a keyboard the
## Input Settings have nothing to offer.

## The settings of the page. They may hide themselves depending on the device.
@export var settings: Array[Control]


func _ready() -> void:
	for setting_control: Control in settings:
		setting_control.visibility_changed.connect(_update_visibility)
	# The settings may hide themselves in their own _ready, which runs after this
	# one for the siblings that come later in the tree.
	_update_visibility.call_deferred()


func _update_visibility() -> void:
	# Check the own visibility of each control, not is_visible_in_tree(), which
	# is also false while the whole page is hidden.
	visible = settings.all(
		func(setting_control: Control) -> bool:
			return not setting_control.visible,
	)
