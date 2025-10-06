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
## they don't count for emitting the signal.
## [br][br]
## It should be in group [b]hook_listener[/b] so functions [method hooked]
## and [method released] are called.

## Emitted when all [member elements] are hooked.
signal all_hooked

## Game elements to consider. They must have a [HookableArea] as direct child.
@export var elements: Array[Node2D]

## The hookable area of each of the [member elements].
var areas_to_hook: Array[HookableArea]

## The [member areas_to_hook] currently hooked.
var areas_hooked: Array[HookableArea]


func _ready() -> void:
	for e in elements:
		for c in e.get_children():
			if c is HookableArea:
				areas_to_hook.append(c)
				break


## Called when the area was released.
## [br][br]
## Part of group hook_listener.
func released(area: HookableArea) -> void:
	if area not in areas_to_hook:
		return
	areas_hooked.erase(area)


## Called when the area was hooked.
## [br][br]
## Part of group hook_listener.
func hooked(area: HookableArea, is_loop: bool) -> void:
	if area not in areas_to_hook:
		return
	areas_hooked.append(area)
	if is_loop and areas_hooked.size() >= areas_to_hook.size() + 1:
		all_hooked.emit()
