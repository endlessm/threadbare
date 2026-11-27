# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name AllHooked
extends Node2D
## @experimental
##
## Emits [signal all_hooked] when all the configured game elements are hooked.
##
## Could be used to create puzzles. This is a piece of the grappling hook mechanic.
## [br][br]
## The game elements configured must have a [HookableArea] as a direct child, otherwise
## they don't count for emitting the signal. The areas must be connections, with
## a [member HookableArea.hook_control].
## [br][br]
## It listens to the [signal HookControl.hooked] and [signal HookControl.released]
## signals of the control of each area. So it counts the throws from one element
## to another, and [signal all_hooked] is emitted when the string goes through all
## the elements and loops back to one of them.

## Emitted when all [member elements] are hooked.
signal all_hooked

## Game elements to consider. They must have a [HookableArea] as direct child.
@export var elements: Array[Node2D]

## The hookable area of each of the [member elements].
var areas_to_hook: Array[HookableArea]

## The [member areas_to_hook] currently hooked from the control of another one.
var areas_hooked: Array[HookableArea]


func _ready() -> void:
	for e in elements:
		for c in e.get_children():
			if c is HookableArea:
				var area: HookableArea = c
				areas_to_hook.append(area)
				if area.hook_control:
					area.hook_control.hooked.connect(hooked)
					area.hook_control.released.connect(released)
				break


## Called when the control of one of the [member areas_to_hook] releases
## [param area]. See [signal HookControl.released].
func released(area: HookableArea) -> void:
	areas_hooked.erase(area)


## Called when the control of one of the [member areas_to_hook] hooks
## [param area]. See [signal HookControl.hooked].
func hooked(area: HookableArea, is_loop: bool) -> void:
	if area not in areas_to_hook:
		return
	areas_hooked.append(area)
	if is_loop and areas_hooked.size() >= areas_to_hook.size():
		all_hooked.emit()
